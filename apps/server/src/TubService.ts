import { EventEmitter } from "events";
import { PrivyClient, WalletWithMetadata } from "@privy-io/server-auth";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";
import { Connection, Keypair, MessageV0, PublicKey, Transaction, VersionedTransaction } from "@solana/web3.js";
import { GqlClient } from "@tub/gql";
import bs58 from "bs58";
import { config } from "dotenv";
import { Subject, Subscription, interval, switchMap } from "rxjs";
import { env } from "../bin/tub-server";
import {
  PrebuildSignedSwapResponse,
  PrebuildSwapResponse,
  UserPrebuildSwapRequest,
} from "../types/PrebuildSwapRequest";
import { OctaneService } from "./OctaneService";

config({ path: "../../.env" });

const USDC_DEV_PUBLIC_KEY = new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"); // The address of the USDC token on Solana Devnet
const USDC_MAINNET_PUBLIC_KEY = new PublicKey("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"); // The address of the USDC token on Solana Mainnet
const SOL_MAINNET_PUBLIC_KEY = new PublicKey("So11111111111111111111111111111111111111112"); // The address of the SOL token on Solana Mainnet

// Internal type that extends UserPrebuildSwapRequest with derived addresses
type ActiveSwapRequest = UserPrebuildSwapRequest & {
  buyTokenAccount: PublicKey;
  sellTokenAccount: PublicKey;
  userPublicKey: PublicKey;
};

/**
 * Type for managing active swap stream subscriptions
 */
interface SwapSubscription {
  /** Subject that emits new swap transactions */
  subject: Subject<PrebuildSwapResponse>;
  /** RxJS subscription for cleanup */
  subscription: Subscription;
}

/**
 * Service class handling token trading, swaps, and user operations
 */
export class TubService {
  private gql: GqlClient["db"];
  private octane: OctaneService;
  private privy: PrivyClient;
  private solUsdPrice: number | undefined;
  private priceEmitter = new EventEmitter();

  private connection: Connection;
  private activeSwapRequests: Map<string, ActiveSwapRequest> = new Map();
  private messageRegistry: Map<string, PrebuildSwapResponse & { message: MessageV0 }> = new Map();
  private swapSubscriptions: Map<string, SwapSubscription> = new Map();

  private readonly SOL_USD_UPDATE_INTERVAL = 5 * 1000; // 10 seconds
  private readonly REGISTRY_TIMEOUT = 5 * 60 * 1000; // 5 minutes in milliseconds

  /**
   * Creates a new instance of TubService
   * @param gqlClient - GraphQL client for database operations
   * @param privy - Privy client for authentication
   * @param octane - OctaneService instance for transaction handling
   */
  constructor(gqlClient: GqlClient["db"], privy: PrivyClient, octane: OctaneService) {
    this.gql = gqlClient;
    this.octane = octane;
    this.privy = privy;

    // Update the SOL/USD price every 10 seconds
    const interval = setInterval(() => {
      this.updateSolUsdPrice();
    }, this.SOL_USD_UPDATE_INTERVAL);
    this.updateSolUsdPrice();

    interval.unref(); // allow Node.js to exit if only this interval is still running
    this.connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`);

    // Start cleanup interval
    setInterval(() => this.cleanupRegistry(), 60 * 1000); // Run cleanup every minute
  }

  private cleanupRegistry() {
    const now = Date.now();
    for (const [key, value] of this.messageRegistry.entries()) {
      if (now - value.timestamp > this.REGISTRY_TIMEOUT) {
        this.messageRegistry.delete(key);
      }
    }
  }

  /**
   * Verifies a JWT token and returns the associated user ID
   * @param token - JWT token to verify
   * @returns The verified user ID
   * @throws Error if JWT is invalid
   */
  protected async verifyJWT(token: string): Promise<string> {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      return verifiedClaims.userId;
    } catch (e: unknown) {
      throw new Error(`Invalid JWT: ${e instanceof Error ? e.message : "Unknown error"}`);
    }
  }

  /**
   * Retrieves a user's Solana wallet address
   * @param userId - The user's ID
   * @returns The user's Solana wallet address or undefined if not found
   */
  protected async getUserWallet(userId: string): Promise<string | undefined> {
    const user = await this.privy.getUserById(userId);

    const solanaWallet = user.linkedAccounts.find(
      (account) => account.type === "wallet" && account.chainType === "solana",
    ) as WalletWithMetadata | undefined;
    return solanaWallet?.address;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async getSignedTransfer(
    jwtToken: string,
    args: { fromAddress: string; toAddress: string; amount: bigint; tokenId: string },
  ): Promise<{ transactionBase64: string; signatureBase64: string; signerBase58: string }> {
    const accountId = await this.verifyJWT(jwtToken);
    if (!accountId) {
      throw new Error("User is not registered with Privy");
    }
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));

    const tokenMint = new PublicKey(args.tokenId);

    const fromPublicKey = new PublicKey(args.fromAddress);
    const toPublicKey = new PublicKey(args.toAddress);

    const fromTokenAccount = getAssociatedTokenAddressSync(tokenMint, fromPublicKey);
    const toTokenAccount = getAssociatedTokenAddressSync(tokenMint, toPublicKey);

    const transferInstruction = createTransferInstruction(fromTokenAccount, toTokenAccount, fromPublicKey, args.amount);

    const transaction = new Transaction();
    transaction.feePayer = feePayerKeypair.publicKey;

    transaction.add(transferInstruction);

    const blockhash = await this.connection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash.blockhash;

    transaction.sign(feePayerKeypair);

    const sigData = transaction.signatures[0];
    if (!sigData) {
      throw new Error("Transaction is not signed by feePayer");
    }
    const { signature: rawSignature, publicKey } = sigData;

    if (!rawSignature) {
      throw new Error("Transaction is not signed by feePayer");
    }

    return {
      transactionBase64: transaction.serialize({ requireAllSignatures: false }).toString("base64"),
      signatureBase64: Buffer.from(rawSignature).toString("base64"),
      signerBase58: publicKey.toBase58(),
    };
  }

  /**
   * Records a client event in the database
   * @param event - Event details to record
   * @param token - JWT token for authentication
   * @returns ID of the recorded event
   * @throws Error if recording fails
   */
  async recordClientEvent(
    event: {
      userAgent: string;
      eventName: string;
      metadata?: string;
      errorDetails?: string;
      source?: string;
      buildVersion?: string;
    },
    token: string,
  ) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.AddClientEventMutation({
      user_agent: event.userAgent,
      event_name: event.eventName,
      metadata: event.metadata,
      user_wallet: wallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    const id = result.data?.insert_analytics_client_event_one?.id;

    if (!id) {
      throw new Error("Failed to record client event. Missing ID.");
    }

    if (result.error) {
      throw new Error(result.error.message);
    }

    return id;
  }

  async getSolUsdPrice(): Promise<number | undefined> {
    if (!this.solUsdPrice) await this.updateSolUsdPrice();
    return this.solUsdPrice;
  }

  subscribeSolPrice(callback: (price: number) => void): () => void {
    this.priceEmitter.on("price", callback);
    // Send current price immediately if available
    if (this.solUsdPrice !== undefined) callback(this.solUsdPrice);

    // Return cleanup function
    return () => {
      this.priceEmitter.off("price", callback);
    };
  }

  private async updateSolUsdPrice(): Promise<void> {
    try {
      const res = await fetch(`${process.env.JUPITER_URL}/price?ids=SOL`);
      const data = (await res.json()) as { data: { [id: string]: { price: number } } };

      this.solUsdPrice = data.data["SOL"]?.price;
      if (this.solUsdPrice !== undefined) this.priceEmitter.emit("price", this.solUsdPrice);

      console.log(`SOL/USD price updated: ${this.solUsdPrice?.toLocaleString("en-US", { maximumFractionDigits: 2 })}`);
    } catch (error) {
      console.error("Error updating SOL/USD price:", error);
    }
  }

  /**
   * Builds a swap transaction for exchanging tokens that enables a server-side fee payer
   * @param jwtToken - The JWT token for user authentication
   * @param request - The swap request parameters
   * @param request.buyTokenId - Public key of the token to receive
   * @param request.sellTokenId - Public key of the token to sell
   * @param request.sellQuantity - Amount of tokens to sell (in token's base units)
   * @returns {Promise<PrebuildSwapResponse>} Object containing the base64-encoded transaction and metadata
   * @throws {Error} If user has no wallet or if swap building fails
   *
   * @remarks
   * The returned transaction will be stored in the registry for 5 minutes. After signing,
   * the user should submit the transaction and signature to `signAndSendTransaction`.
   *
   * @example
   * // Get transaction to swap 1 USDC for SOL
   * const response = await tubService.fetchSwap(jwt, {
   *   buyTokenId: "So11111111111111111111111111111111111111112",  // SOL
   *   sellTokenId: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", // USDC
   *   sellQuantity: 1e6 // 1 USDC. Other tokens may be 1e9 standard
   * });
   */
  async fetchSwap(jwtToken: string, request: UserPrebuildSwapRequest): Promise<PrebuildSwapResponse> {
    const userId = await this.verifyJWT(jwtToken);

    const userWallet = await this.getUserWallet(userId);
    if (!userWallet) {
      throw new Error("User does not have a wallet registered with Privy");
    }

    const userPublicKey = new PublicKey(userWallet);

    const derivedAccounts = await this.deriveTokenAccounts(userPublicKey, request.buyTokenId, request.sellTokenId);

    const activeRequest: ActiveSwapRequest = {
      ...request,
      ...derivedAccounts,
      userPublicKey,
    };

    try {
      const response = await this.buildSwapResponse(activeRequest);
      return response;
    } catch (error) {
      throw new Error(`Failed to build swap response: ${error}`);
    }
  }
  /**
   * Builds a swap transaction for exchanging tokens and signs it with the fee payer.
   * @dev Once user signs, the transaction is complete and can be directly submitted to Solana RPC by the user.
   * @param jwtToken - The JWT token for user authentication
   * @param request - The swap request parameters
   * @param request.buyTokenId - Public key of the token to receive
   * @param request.sellTokenId - Public key of the token to sell
   * @param request.sellQuantity - Amount of tokens to sell (in token's base units)
   * @returns {Promise<PrebuildSwapResponse>} Object containing the base64-encoded transaction and metadata
   * @throws {Error} If user has no wallet or if swap building fails
   *
   * @example
   * const response = await tubService.fetchSwap(jwt, {
   *   buyTokenId: "So11111111111111111111111111111111111111112",  // SOL
   *   sellTokenId: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", // USDC
   *   sellQuantity: 1e6 // 1 USDC. Other tokens may be 1e9 standard
   * });
   */
  async fetchPresignedSwap(jwtToken: string, request: UserPrebuildSwapRequest): Promise<PrebuildSignedSwapResponse> {
    const fetchSwapResponse = await this.fetchSwap(jwtToken, request);
    // fetch transaction from registry
    const registryEntry = this.messageRegistry.get(fetchSwapResponse.transactionMessageBase64);
    if (!registryEntry) {
      throw new Error("Transaction not found in registry");
    }
    const message = registryEntry.message;

    const transaction = new VersionedTransaction(message);

    // remove transaction from registry
    this.messageRegistry.delete(fetchSwapResponse.transactionMessageBase64);

    const feePayerSignature = await this.octane.signTransactionWithoutCheckingTokenFee(transaction);

    const fetchSignedSwapResponse: PrebuildSignedSwapResponse = {
      ...fetchSwapResponse,
      feePayerSignature,
    };

    return fetchSignedSwapResponse;
  }

  /**
   * A test transaction with hardcoded 1 USDC to sell into SOL
   * @param jwtToken - The user's JWT token
   * @returns A constructed, signable transaction
   */
  async get1USDCToSOLTransaction(jwtToken: string) {
    return this.fetchSwap(jwtToken, {
      buyTokenId: SOL_MAINNET_PUBLIC_KEY.toString(),
      sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
      sellQuantity: 1e6, // 1 USDC
    });
  }

  /**
   * Starts a stream of built swap transactions for a user to sign
   * @param jwtToken - The user's JWT token
   * @param request - The swap request parameters
   * @returns A Subject that emits base64-encoded transactions
   */
  async startSwapStream(jwtToken: string, request: UserPrebuildSwapRequest) {
    const userId = await this.verifyJWT(jwtToken);
    const userWallet = await this.getUserWallet(userId);
    if (!userWallet) {
      throw new Error("User does not have a wallet registered with Privy");
    }

    const userPublicKey = new PublicKey(userWallet);
    const derivedAccounts = await this.deriveTokenAccounts(userPublicKey, request.buyTokenId, request.sellTokenId);

    // Store the enhanced request
    this.activeSwapRequests.set(userId, {
      ...request,
      ...derivedAccounts,
      userPublicKey,
    });

    if (!this.swapSubscriptions.has(userId)) {
      const subject = new Subject<PrebuildSwapResponse>();

      // Create 1-second interval stream
      const subscription = interval(1000)
        .pipe(
          switchMap(async () => {
            const currentRequest = this.activeSwapRequests.get(userId);
            if (!currentRequest) return null;
            return this.buildSwapResponse(currentRequest);
          }),
        )
        .subscribe((response: PrebuildSwapResponse | null) => {
          if (response) {
            subject.next(response);
          }
        });

      this.swapSubscriptions.set(userId, { subject, subscription });
    }

    return this.swapSubscriptions.get(userId)!.subject;
  }

  /**
   * Updates parameters for an active swap request and returns a new transaction
   * @param jwtToken - The user's JWT token
   * @param updates - New parameters to update
   * @returns New swap transaction with updated parameters
   * @throws Error If no active request exists or if building new transaction fails
   *
   * @remarks
   * If token IDs are changed, new token accounts will be derived.
   * The new transaction will be stored in the registry for 5 minutes.
   *
   * @example
   * // Update sell quantity to 2 USDC
   * const response = await tubService.updateSwapRequest(jwt, {
   *   sellQuantity: 2e6 // Other tokens may have 1e9 standard
   * });
   */
  async updateSwapRequest(jwtToken: string, updates: Partial<UserPrebuildSwapRequest>) {
    const userId = await this.verifyJWT(jwtToken);
    const userWallet = await this.getUserWallet(userId);
    if (!userWallet) {
      throw new Error("User does not have a wallet registered with Privy");
    }
    const userPublicKey = new PublicKey(userWallet);

    const current = this.activeSwapRequests.get(userId);
    if (current) {
      // Re-derive accounts if tokens changed
      const needsNewDerivedAccounts =
        (updates.buyTokenId && updates.buyTokenId !== current.buyTokenId) ||
        (updates.sellTokenId && updates.sellTokenId !== current.sellTokenId);

      const derivedAccounts = needsNewDerivedAccounts
        ? this.deriveTokenAccounts(
            userPublicKey,
            updates.buyTokenId ?? current.buyTokenId,
            updates.sellTokenId ?? current.sellTokenId,
          )
        : {};

      const updated = { ...current, ...updates, ...derivedAccounts };

      // Update active request for streaming
      this.activeSwapRequests.set(userId, updated);

      // Build new swap response and update registry
      try {
        const response = await this.buildSwapResponse(updated);
        return response;
      } catch (error) {
        throw new Error(`Failed to build updated swap response: ${error}`);
      }
    } else {
      throw new Error(`[updateSwapRequest] No active swap request found for user ${userId}`);
    }
  }

  /**
   * Stops an active swap stream for a user
   * @param jwtToken - The user's JWT token
   */
  async stopSwapStream(jwtToken: string) {
    const userId = await this.verifyJWT(jwtToken);

    this.activeSwapRequests.delete(userId);
    const swapSubscription = this.swapSubscriptions.get(userId);
    if (swapSubscription) {
      swapSubscription.subscription.unsubscribe();
      swapSubscription.subject.complete();
      this.swapSubscriptions.delete(userId);
    } else {
      throw new Error(`[stopSwapStream] No active stream found for user ${userId}`);
    }
  }

  /**
   * Validates, signs, and sends a transaction with user and fee payer signatures
   * @param jwtToken - The user's JWT token
   * @param userSignature - The user's base64-encoded signature for the transaction
   * @param base64TransactionMessage - The original base64-encoded transaction message from fetchSwap
   * @returns Object containing the transaction signature
   * @throws Error if transaction not found in registry, invalid signatures, or processing fails
   *
   * @remarks
   * This method expects the exact transaction returned by fetchSwap. The transaction must
   * be in the registry (valid for 5 minutes) and must be signed by the user. The server
   * will add the fee payer signature and submit the transaction.
   */
  async signAndSendTransaction(jwtToken: string, userSignature: string, base64TransactionMessage: string) {
    try {
      const userId = await this.verifyJWT(jwtToken);

      const registryEntry = this.messageRegistry.get(base64TransactionMessage);
      if (!registryEntry) {
        throw new Error("Transaction not found in registry");
      }

      const walletAddress = await this.getUserWallet(userId);
      if (!walletAddress) {
        throw new Error("User does not have a wallet registered with Privy");
      }
      const userPublicKey = new PublicKey(walletAddress);
      // Create a new transaction from the registry entry
      const message = registryEntry.message;
      const transaction = new VersionedTransaction(message);

      // Convert base64 signature to bytes
      const userSignatureBytes = Buffer.from(userSignature, "base64");
      transaction.addSignature(userPublicKey, userSignatureBytes);

      // Don't need to validate that we are receiving token fee, given that we already have a tx registry from earlier
      const feePayerSignature = await this.octane.signTransactionWithoutCheckingTokenFee(transaction);
      const feePayerSignatureBytes = Buffer.from(bs58.decode(feePayerSignature));
      const settings = this.octane.getSettings();
      transaction.addSignature(settings.feePayerPublicKey, feePayerSignatureBytes);

      // simulate the transaction
      const simulation = await settings.connection.simulateTransaction(transaction);
      if (simulation.value?.err) {
        throw new Error(`Transaction simulation failed: ${JSON.stringify(simulation.value.err)}`);
      }

      // Send transaction
      const txid = await settings.connection.sendTransaction(transaction, {
        skipPreflight: false,
        maxRetries: 3,
        preflightCommitment: "confirmed",
      });

      const signatureStatus = await settings.connection.getSignatureStatuses([txid]);
      console.log("[signAndSendTransaction] Signature status:", signatureStatus);

      // Wait for confirmation using polling
      let confirmation = null;
      for (let attempt = 0; attempt < 3; attempt++) {
        confirmation = await settings.connection.getTransaction(txid, {
          commitment: "confirmed",
          maxSupportedTransactionVersion: 0,
        });

        if (confirmation) {
          break; // Exit loop if confirmation is received
        }

        console.log(`[signAndSendTransaction] Waiting for confirmation... Attempt ${attempt + 1}`);
        await new Promise((resolve) => setTimeout(resolve, 1000)); // Wait for 1 second before retrying
      }

      if (confirmation == null) {
        throw new Error(`Transaction not found: ${txid}`);
      }

      if (confirmation?.meta?.err) {
        throw new Error(`Transaction failed: ${confirmation.meta.err}`);
      }
      console.log(`[signAndSendTransaction] Transaction confirmed:`, confirmation);

      // Clean up registry
      this.messageRegistry.delete(base64TransactionMessage);

      return { signature: txid };
    } catch (error) {
      // Handle all other errors
      console.error("[signAndSendTransaction] Error:", error);
      throw error;
    }
  }

  /**
   * Derives associated token accounts for buy and sell tokens
   * @param userPublicKey - The user's public key
   * @param buyTokenId - ID of token to buy
   * @param sellTokenId - ID of token to sell
   * @returns Object containing derived token account addresses
   */
  private deriveTokenAccounts(
    userPublicKey: PublicKey,
    buyTokenId: string,
    sellTokenId: string,
  ): { buyTokenAccount: PublicKey; sellTokenAccount: PublicKey } {
    const buyTokenAccount = getAssociatedTokenAddressSync(new PublicKey(buyTokenId), userPublicKey, false);

    const sellTokenAccount = getAssociatedTokenAddressSync(new PublicKey(sellTokenId), userPublicKey, false);

    return { buyTokenAccount, sellTokenAccount };
  }

  private async buildSwapResponse(request: ActiveSwapRequest): Promise<PrebuildSwapResponse> {
    if (!request.sellTokenAccount) {
      throw new Error("Sell token account is required but was not provided");
    }

    // if sell token is either USDC Devnet or Mainnet, use the buy fee amount. otherwise use 0
    const usdcDevPubKey = USDC_DEV_PUBLIC_KEY.toString();
    const usdcMainPubKey = USDC_MAINNET_PUBLIC_KEY.toString();
    const solMainPubKey = SOL_MAINNET_PUBLIC_KEY.toString();
    const _feeAmount =
      request.sellTokenId === usdcDevPubKey || request.sellTokenId === usdcMainPubKey
        ? this.octane.getSettings().buyFee
        : 0;

    const feeAmount = Number((BigInt(_feeAmount) * BigInt(request.sellQuantity)) / 10000n);

    const feeOptions = {
      sourceAccount: request.sellTokenAccount,
      destinationAccount: this.octane.getSettings().tradeFeeRecipient,
      amount: feeAmount,
    };

    const feeTransferInstruction = feeOptions
      ? createTransferInstruction(
          feeOptions.sourceAccount,
          feeOptions.destinationAccount,
          request.userPublicKey,
          feeOptions.amount,
        )
      : null;
    // if the sell token is SOL and the buy token is USDC, set to true. if the sell token is USDC and the buy token is SOL, set to true. otherwise, set to false.
    const onlyDirectRoutes =
      (request.sellTokenId === solMainPubKey && request.buyTokenId === usdcMainPubKey) ||
      (request.sellTokenId === usdcMainPubKey && request.buyTokenId === solMainPubKey);

    const swapInstructionRequest = {
      inputMint: request.sellTokenId,
      outputMint: request.buyTokenId,
      amount: request.sellQuantity - feeAmount,
      slippageBps: 50,
      onlyDirectRoutes,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    const { instructions: swapInstructions, addressLookupTableAccounts } = await this.octane.getSwapInstructions(
      swapInstructionRequest,
      request.userPublicKey,
    );

    if (!swapInstructions?.length) {
      throw new Error("No swap instruction received");
    }

    const allInstructions = feeTransferInstruction ? [feeTransferInstruction, ...swapInstructions] : swapInstructions;
    const message = await this.octane.buildSwapMessage(allInstructions, addressLookupTableAccounts);

    const response: PrebuildSwapResponse = {
      transactionMessageBase64: Buffer.from(message.serialize()).toString("base64"),
      ...request,
      hasFee: feeAmount > 0,
      timestamp: Date.now(),
    };

    // Store in registry with fee information
    this.messageRegistry.set(response.transactionMessageBase64, { ...response, message });

    return response;
  }
}
