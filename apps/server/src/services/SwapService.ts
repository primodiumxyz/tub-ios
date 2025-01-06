import { Subject, interval, switchMap } from "rxjs";
import { JupiterService } from "./JupiterService";
import { TransactionService } from "./TransactionService";
import { FeeService } from "../services/FeeService";
import { ActiveSwapRequest, PrebuildSwapResponse, SwapSubscription, SwapType } from "../types";
import { USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";
import { QuoteGetRequest } from "@jup-ag/api";
import { Connection, PublicKey, TransactionInstruction } from "@solana/web3.js";
import {
  MAX_ACCOUNTS,
  MAX_DEFAULT_SLIPPAGE_BPS,
  MAX_AUTO_SLIPPAGE_BPS,
  AUTO_SLIPPAGE,
  AUTO_SLIPPAGE_COLLISION_USD_VALUE,
  AUTO_PRIORITY_FEE_MULTIPLIER,
  USER_SLIPPAGE_BPS_MAX,
  MIN_SLIPPAGE_BPS,
} from "../constants/swap";

export class SwapService {
  private swapSubscriptions: Map<string, SwapSubscription> = new Map();

  constructor(
    private jupiter: JupiterService,
    private transactionService: TransactionService,
    private feeService: FeeService,
    private connection: Connection,
  ) {}

  async buildSwapResponse(request: ActiveSwapRequest): Promise<PrebuildSwapResponse> {
    if (!request.sellTokenAccount) {
      throw new Error("Sell token account is required but was not provided");
    }

    if (request.slippageBps && request.slippageBps > USER_SLIPPAGE_BPS_MAX) {
      throw new Error("Slippage bps is too high");
    }

    if (request.slippageBps && request.slippageBps < MIN_SLIPPAGE_BPS) {
      throw new Error("Slippage bps must be greater than " + MIN_SLIPPAGE_BPS);
    }

    // Determine swap type
    const swapType = await this.determineSwapType(request);

    // Calculate fee if buying memecoin
    const buyFeeAmount = this.feeService.calculateBuyFeeAmount(request.sellQuantity, swapType);
    const swapAmount = request.sellQuantity - buyFeeAmount;

    // Create fee transfer instruction if swap type is buy
    const buyFeeTransferInstruction =
      swapType === SwapType.BUY
        ? this.feeService.createFeeTransferInstruction(request.sellTokenAccount, request.userPublicKey, buyFeeAmount)
        : null;

    // Create token account close instruction if fee amount is 0
    const tokenCloseInstruction = await this.transactionService.createTokenCloseInstruction(
      request.userPublicKey,
      request.sellTokenAccount,
      new PublicKey(request.sellTokenId),
      request.sellQuantity,
      swapType,
    );

    // TODO: autoSlippageCollisionUsdValue should be based on the estimated value of the swap amount.
    // This is already accomplished when selling USDC, but need to query our internal price feed for other tokens.

    // there are 3 different forms of slippage settings, ordered by priority
    // 1. user provided slippage bps
    // 2. auto slippage set to true with a max slippage bps
    // 3. auto slippage set to false, use MAX_DEFAULT_SLIPPAGE_BPS

    const slippageSettings = {
      slippageBps: request.slippageBps ? request.slippageBps : AUTO_SLIPPAGE ? undefined : MAX_DEFAULT_SLIPPAGE_BPS,
      autoSlippage: request.slippageBps ? false : AUTO_SLIPPAGE,
      maxAutoSlippageBps: MAX_AUTO_SLIPPAGE_BPS,
      autoSlippageCollisionUsdValue:
        request.sellTokenId === USDC_MAINNET_PUBLIC_KEY.toString()
          ? Math.ceil(swapAmount / 1e6)
          : AUTO_SLIPPAGE_COLLISION_USD_VALUE,
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
      maxAccounts: MAX_ACCOUNTS,
      asLegacyTransaction: false,
    };

    const {
      instructions: swapInstructions,
      addressLookupTableAccounts,
      quote,
    } = await this.jupiter.getSwapInstructions(
      swapInstructionRequest,
      request.userPublicKey,
      AUTO_PRIORITY_FEE_MULTIPLIER,
    );
    console.log("Quoted auto slippage", quote.computedAutoSlippage);
    console.log("Quoted slippage bps", quote.slippageBps);
    console.log("Quoted outAmount", quote.outAmount);

    if (!swapInstructions?.length) {
      throw new Error("No swap instruction received");
    }

    let sellFeeTransferInstruction: TransactionInstruction | null = null;

    if (swapType === SwapType.SELL_ALL || swapType === SwapType.SELL_PARTIAL) {
      const sellFeeAmount = this.feeService.calculateSellFeeAmount(request.sellQuantity);
      sellFeeTransferInstruction = this.feeService.createFeeTransferInstruction(
        request.sellTokenAccount,
        request.userPublicKey,
        sellFeeAmount,
      );
    }

    const organizedInstructions = await this.organizeInstructions(
      swapInstructions,
      buyFeeTransferInstruction,
      sellFeeTransferInstruction,
      tokenCloseInstruction,
    );

    // Reassign rent payer in instructions
    const rentReassignedInstructions = this.transactionService.reassignRentInstructions(organizedInstructions);

    // Build transaction message
    const message = await this.transactionService.buildTransactionMessage(
      rentReassignedInstructions,
      addressLookupTableAccounts,
    );

    // Register transaction
    const base64Message = this.transactionService.registerTransaction(message);

    const response: PrebuildSwapResponse = {
      transactionMessageBase64: base64Message,
      ...request,
      hasFee: !!buyFeeTransferInstruction || !!sellFeeTransferInstruction,
      timestamp: Date.now(),
    };

    return response;
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
      throw new Error(`Not enough memecoin balance. Observed balance: ${Number(sellTokenBalance.value.amount)}`);
    } else {
      return SwapType.BUY;
    }
  }

  private async organizeInstructions(
    swapInstructions: TransactionInstruction[],
    buyFeeInstruction: TransactionInstruction | null,
    sellFeeInstruction: TransactionInstruction | null,
    tokenCloseInstruction: TransactionInstruction | null,
  ): Promise<TransactionInstruction[]> {
    const instructions = [...swapInstructions];
    if (buyFeeInstruction) {
      instructions.push(buyFeeInstruction);
    }
    if (sellFeeInstruction) {
      instructions.push(sellFeeInstruction);
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
            return this.buildSwapResponse(currentRequest);
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
