import { Subject, interval, switchMap } from "rxjs";
import { JupiterService } from "./JupiterService";
import { TransactionService } from "./TransactionService";
import { FeeService } from "../services/FeeService";
import { ActiveSwapRequest, PrebuildSwapResponse, SwapSubscription, SwapType } from "../types";
import { QuoteGetRequest } from "@jup-ag/api";
import { Connection, PublicKey, TransactionInstruction } from "@solana/web3.js";
import { USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";
import { Config } from "./ConfigService";
import { config } from "../utils/config";

export class SwapService {
  private swapSubscriptions: Map<string, SwapSubscription> = new Map();

  constructor(
    private jupiter: JupiterService,
    private transactionService: TransactionService,
    private feeService: FeeService,
    private connection: Connection,
  ) {
    // Tell TransactionService about this SwapService instance
    this.transactionService.setSwapService(this);
  }

  async buildSwapResponse(
    request: ActiveSwapRequest,
    cfg: Config,
    priorBuildAttempts: number = 0,
  ): Promise<PrebuildSwapResponse> {
    if (!request.sellTokenAccount) {
      throw new Error("Sell token account is required but was not provided");
    }

    if (request.slippageBps && request.slippageBps > cfg.USER_SLIPPAGE_BPS_MAX) {
      throw new Error("Slippage bps is too high");
    }

    if (request.slippageBps && request.slippageBps < cfg.MIN_SLIPPAGE_BPS) {
      throw new Error("Slippage bps must be greater than " + cfg.MIN_SLIPPAGE_BPS);
    }

    // Determine swap type
    const swapType = await this.determineSwapType(request);

    // Calculate fee if swap type is buy
    const buyFeeAmount =
      SwapType.BUY === swapType ? this.feeService.calculateFeeAmount(request.sellQuantity, swapType, cfg) : 0;
    const swapAmount = request.sellQuantity - buyFeeAmount;

    // Create token account close instruction if swap type is sell_all (conditional occurs within function)
    const tokenCloseInstruction = await this.transactionService.createTokenCloseInstruction(
      request.userPublicKey,
      request.sellTokenAccount,
      new PublicKey(request.sellTokenId),
      request.sellQuantity,
      swapType,
    );

    // there are 3 different forms of slippage settings, ordered by priority
    // 1. user provided slippage bps
    // 2. auto slippage set to true with a max slippage bps
    // 3. auto slippage set to false, use MAX_DEFAULT_SLIPPAGE_BPS

    const slippageSettings = {
      slippageBps: request.slippageBps
        ? request.slippageBps
        : cfg.AUTO_SLIPPAGE
          ? undefined
          : cfg.MAX_DEFAULT_SLIPPAGE_BPS,
      autoSlippage: request.slippageBps ? false : cfg.AUTO_SLIPPAGE,
      maxAutoSlippageBps: cfg.MAX_AUTO_SLIPPAGE_BPS,
      autoSlippageCollisionUsdValue: cfg.AUTO_SLIPPAGE_COLLISION_USD_VALUE,
    };

    // Get swap instructions from Jupiter
    // if slippageBps is provided, use it
    // if slippageBps is not provided, use autoSlippage if its true, otherwise use MAX_DEFAULT_SLIPPAGE_BPS
    const swapInstructionRequest: QuoteGetRequest = {
      inputMint: request.sellTokenId,
      outputMint: request.buyTokenId,
      amount: swapAmount,
      slippageBps: slippageSettings.slippageBps,
      autoSlippage: slippageSettings.autoSlippage,
      maxAutoSlippageBps: slippageSettings.maxAutoSlippageBps,
      autoSlippageCollisionUsdValue: slippageSettings.autoSlippageCollisionUsdValue,
      onlyDirectRoutes: false,
      restrictIntermediateTokens: true,
      maxAccounts: cfg.MAX_ACCOUNTS,
      asLegacyTransaction: false,
    };

    // TODO: config for max build attempts
    const MAX_BUILD_ATTEMPTS = 3;

    // Where rebuilding occurs
    for (let buildAttempt = priorBuildAttempts + 1; buildAttempt < MAX_BUILD_ATTEMPTS + 1; buildAttempt++) {
      console.log("Building swap response attempt " + buildAttempt);
      try {
        const {
          instructions: swapInstructions,
          addressLookupTableAccounts,
          quote,
        } = await this.jupiter.getSwapInstructions(swapInstructionRequest, request.userPublicKey);
        console.log("Quoted auto slippage", quote.computedAutoSlippage);
        console.log("Quoted slippage bps", quote.slippageBps);
        console.log("Quoted outAmount", quote.outAmount);
        console.log("Quote Slot Context", quote.contextSlot);

        if (!swapInstructions?.length) {
          throw new Error("No swap instruction received");
        }

        let feeTransferInstruction: TransactionInstruction | null = null;

        // Create fee transfer instruction
        if (swapType === SwapType.BUY) {
          feeTransferInstruction = this.feeService.createFeeTransferInstruction(
            request.sellTokenAccount,
            request.userPublicKey,
            buyFeeAmount,
          );
        } else if (swapType === SwapType.SELL_ALL || swapType === SwapType.SELL_PARTIAL) {
          const sellFeeAmount = this.feeService.calculateFeeAmount(Number(quote.outAmount), swapType, cfg);
          feeTransferInstruction = this.feeService.createFeeTransferInstruction(
            request.buyTokenAccount,
            request.userPublicKey,
            sellFeeAmount,
          );
        } else {
          throw new Error("Invalid swap type");
        }

        const organizedInstructions = this.organizeInstructions(
          swapInstructions,
          feeTransferInstruction,
          tokenCloseInstruction,
        );

        // Reassign rent payer in instructions
        const rentReassignedInstructions = this.transactionService.reassignRentInstructions(organizedInstructions);

        // estimate compute budget
        const optimizedInstructions = await this.transactionService.optimizeComputeInstructions(
          rentReassignedInstructions,
          addressLookupTableAccounts,
          quote.contextSlot ?? 0,
          cfg,
        );

        // Build transaction message
        const message = await this.transactionService.buildTransactionMessage(
          optimizedInstructions,
          addressLookupTableAccounts,
        );

        // Register transaction
        const base64Message = this.transactionService.registerTransaction(
          message,
          swapType,
          slippageSettings.autoSlippage,
          quote.contextSlot ?? 0,
          buildAttempt,
          request,
          cfg,
        );

        const response: PrebuildSwapResponse = {
          transactionMessageBase64: base64Message,
          ...request,
          hasFee: !!feeTransferInstruction,
          timestamp: Date.now(),
        };

        return response;
      } catch (error) {
        console.log("Swap build attempt " + buildAttempt + " failed: " + JSON.stringify(error));
        // TODO: interpret error before retrying to validate if slippage issue

        if (buildAttempt >= MAX_BUILD_ATTEMPTS || !slippageSettings.autoSlippage) {
          throw new Error(error as string);
        }
        continue; // try again in next loop
      }
    }

    // Should never reach here, just satisfying typescript linter
    throw new Error("Swap build failed after " + MAX_BUILD_ATTEMPTS + " attempts");
  }

  private async determineSwapType(request: ActiveSwapRequest): Promise<SwapType> {
    if (request.buyTokenId === USDC_MAINNET_PUBLIC_KEY.toString()) {
      const sellTokenBalance = await this.connection.getTokenAccountBalance(request.sellTokenAccount, "processed");
      if (!sellTokenBalance.value.amount) {
        throw new Error("Sell token balance is null");
      }
      // if balance is greater than sellQuantity, return SELL_PARTIAL
      if (Number(sellTokenBalance.value.amount) > request.sellQuantity) {
        return SwapType.SELL_PARTIAL;
      }
      // if balance is equal to sellQuantity, return SELL_ALL
      if (Number(sellTokenBalance.value.amount) === request.sellQuantity) {
        return SwapType.SELL_ALL;
      }
      // otherwise, throw error as not enough balance. show balance in thrown error.
      throw new Error(`Not enough memecoin balance. Observed balance: ${Number(sellTokenBalance.value.uiAmount)}`);
    } else {
      return SwapType.BUY;
    }
  }

  private organizeInstructions(
    swapInstructions: TransactionInstruction[],
    feeTransferInstruction: TransactionInstruction | null,
    tokenCloseInstruction: TransactionInstruction | null,
  ): TransactionInstruction[] {
    const instructions = [...swapInstructions];
    if (feeTransferInstruction) {
      instructions.push(feeTransferInstruction);
    }
    if (tokenCloseInstruction) {
      instructions.push(tokenCloseInstruction);
    }
    return instructions;
  }

  getMessageFromRegistry(transactionMessageBase64: string) {
    return this.transactionService.getRegisteredTransaction(transactionMessageBase64);
  }

  deleteMessageFromRegistry(transactionMessageBase64: string) {
    this.transactionService.deleteFromRegistry(transactionMessageBase64);
  }

  hasActiveStream(userId: string): boolean {
    return this.swapSubscriptions.has(userId);
  }

  getActiveRequest(userId: string): ActiveSwapRequest | undefined {
    return this.swapSubscriptions.get(userId)?.request;
  }

  updateActiveRequest(userId: string, request: ActiveSwapRequest): void {
    const subscription = this.swapSubscriptions.get(userId);
    if (!subscription) {
      throw new Error("No active swap stream found");
    }
    subscription.request = request;
  }

  async startSwapStream(userId: string, request: ActiveSwapRequest) {
    if (!this.swapSubscriptions.has(userId)) {
      const subject = new Subject<PrebuildSwapResponse>();

      // Create 1-second interval stream
      const subscription = interval(1000)
        .pipe(
          switchMap(async () => {
            const currentRequest = this.swapSubscriptions.get(userId)?.request;
            if (!currentRequest) return null;
            const cfg = await config();
            return this.buildSwapResponse(currentRequest, cfg);
          }),
        )
        .subscribe((response: PrebuildSwapResponse | null) => {
          if (response) {
            subject.next(response);
          }
        });

      this.swapSubscriptions.set(userId, { subject, subscription, request });
    }

    return this.swapSubscriptions.get(userId)?.subject;
  }

  async stopSwapStream(userId: string) {
    const subscription = this.swapSubscriptions.get(userId);
    if (subscription) {
      subscription.subscription.unsubscribe();
      subscription.subject.complete();
      this.swapSubscriptions.delete(userId);
    }
  }
}
