import { PublicKey } from "@solana/web3.js";
import { Subject, interval, switchMap } from "rxjs";
import { JupiterService } from "./JupiterService";
import { TransactionService } from "./TransactionService";
import { FeeService } from "../services/FeeService";
import { ActiveSwapRequest, PrebuildSwapResponse, SwapSubscription } from "../types";
import { QuoteGetRequest } from "@jup-ag/api";
import { USDC_MAINNET_PUBLIC_KEY, USDC_DEV_PUBLIC_KEY } from "../constants/tokens";
import { config } from "../utils/config";

export class SwapService {
  private swapSubscriptions: Map<string, SwapSubscription> = new Map();

  constructor(
    private jupiter: JupiterService,
    private transactionService: TransactionService,
    private feeService: FeeService,
  ) {}

  async buildSwapResponse(request: ActiveSwapRequest): Promise<PrebuildSwapResponse> {
    if (!request.sellTokenAccount) {
      throw new Error("Sell token account is required but was not provided");
    }

    if (request.slippageBps && request.slippageBps > config().USER_SLIPPAGE_BPS_MAX) {
      throw new Error("Slippage bps is too high");
    }

    if (request.slippageBps && request.slippageBps <= config().MIN_SLIPPAGE_BPS) {
      throw new Error("Slippage bps must be greater than " + config().MIN_SLIPPAGE_BPS);
    }

    // Calculate fee if selling USDC
    const feeAmount = this.feeService.calculateFeeAmount(request.sellTokenId, request.sellQuantity, [
      USDC_DEV_PUBLIC_KEY.toString(),
      USDC_MAINNET_PUBLIC_KEY.toString(),
    ]);
    const swapAmount = request.sellQuantity - feeAmount;

    // Create fee transfer instruction if needed
    const feeTransferInstruction = this.feeService.createFeeTransferInstruction(
      request.sellTokenAccount,
      request.userPublicKey,
      feeAmount,
    );

    // TODO: autoSlippageCollisionUsdValue should be based on the estimated value of the swap amount.
    // This is already accomplished when selling USDC, but need to query our internal price feed for other tokens.

    // there are 3 different forms of slippage settings, ordered by priority
    // 1. user provided slippage bps
    // 2. auto slippage set to true with a max slippage bps
    // 3. auto slippage set to false, use MAX_DEFAULT_SLIPPAGE_BPS

    const slippageSettings = {
      slippageBps: request.slippageBps
        ? request.slippageBps
        : config().AUTO_SLIPPAGE
          ? undefined
          : config().MAX_DEFAULT_SLIPPAGE_BPS,
      autoSlippage: request.slippageBps ? false : config().AUTO_SLIPPAGE,
      maxAutoSlippageBps: config().MAX_AUTO_SLIPPAGE_BPS,
      autoSlippageCollisionUsdValue:
        request.sellTokenId === USDC_MAINNET_PUBLIC_KEY.toString()
          ? Math.ceil(swapAmount / 1e6)
          : config().AUTO_SLIPPAGE_COLLISION_USD_VALUE,
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
      maxAccounts: config().MAX_ACCOUNTS,
      asLegacyTransaction: false,
    };

    const {
      instructions: swapInstructions,
      addressLookupTableAccounts,
      quote,
    } = await this.jupiter.getSwapInstructions(
      swapInstructionRequest,
      request.userPublicKey,
      config().AUTO_PRIORITY_FEE_MULTIPLIER,
    );
    console.log("Quoted auto slippage", quote.computedAutoSlippage);
    console.log("Quoted slippage bps", quote.slippageBps);
    console.log("Quoted outAmount", quote.outAmount);

    if (!swapInstructions?.length) {
      throw new Error("No swap instruction received");
    }

    // Combine fee transfer and swap instructions
    const allInstructions = feeTransferInstruction ? [feeTransferInstruction, ...swapInstructions] : swapInstructions;

    // Reassign rent payer in instructions
    const rentReassignedInstructions = this.transactionService.reassignRentInstructions(allInstructions);

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
      hasFee: feeAmount > 0,
      timestamp: Date.now(),
    };

    return response;
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

  async signAndSendTransaction(
    userPublicKey: PublicKey,
    userSignature: string,
    base64TransactionMessage: string,
  ): Promise<{ signature: string }> {
    return this.transactionService.signAndSendTransaction(userPublicKey, userSignature, base64TransactionMessage);
  }
}
