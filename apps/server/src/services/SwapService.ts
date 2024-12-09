import { Connection, PublicKey } from "@solana/web3.js";
import { Subject, interval, switchMap } from "rxjs";
import { JupiterService } from "../JupiterService";
import { TransactionService } from "./TransactionService";
import { FeeService } from "../services/FeeService";
import { ActiveSwapRequest, PrebuildSwapResponse, SwapSubscription } from "../types";
import { USDC_DEV_PUBLIC_KEY, USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";

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

    // Calculate fee if selling USDC
    const usdcDevPubKey = USDC_DEV_PUBLIC_KEY.toString();
    const usdcMainPubKey = USDC_MAINNET_PUBLIC_KEY.toString();
    const feeAmount = this.feeService.calculateFeeAmount(request.sellTokenId, request.sellQuantity, [
      usdcDevPubKey,
      usdcMainPubKey,
    ]);

    // Create fee transfer instruction if needed
    const feeTransferInstruction = this.feeService.createFeeTransferInstruction(
      request.sellTokenAccount,
      request.userPublicKey,
      feeAmount,
    );

    // Get swap instructions from Jupiter
    const swapInstructionRequest = {
      inputMint: request.sellTokenId,
      outputMint: request.buyTokenId,
      amount: request.sellQuantity - feeAmount,
      slippageBps: 50,
      onlyDirectRoutes: false,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    const { instructions: swapInstructions, addressLookupTableAccounts } = await this.jupiter.getSwapInstructions(
      swapInstructionRequest,
      request.userPublicKey,
    );

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
