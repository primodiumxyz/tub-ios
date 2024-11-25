import { Codex } from "@codex-data/sdk";
import { PrivyClient, WalletWithMetadata } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";
import { OctaneService } from "./OctaneService";
import { Subject, interval, switchMap } from 'rxjs';
import { PublicKey, SendTransactionError, Transaction } from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddress } from "@solana/spl-token";
import { UserPrebuildSwapRequest, PrebuildSwapResponse } from "../types/PrebuildSwapRequest";
import bs58 from 'bs58';

config({ path: "../../.env" });

const USDC_DEV_PUBLIC_KEY = new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"); // The address of the USDC token on Solana Devnet
const USDC_MAINNET_PUBLIC_KEY = new PublicKey("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"); // The address of the USDC token on Solana Mainnet
const SOL_MAINNET_PUBLIC_KEY = new PublicKey("So11111111111111111111111111111111111111112"); // The address of the SOL token on Solana Mainnet

// Internal type that extends UserPrebuildSwapRequest with derived addresses
type ActiveSwapRequest = UserPrebuildSwapRequest & {
  buyTokenAccount?: PublicKey;
  sellTokenAccount?: PublicKey;
  userPublicKey: PublicKey;
};

/**
 * Service class handling token trading, swaps, and user operations
 */
export class TubService {
  private gql: GqlClient["db"];
  private octane: OctaneService;
  private privy: PrivyClient;
  private codexSdk: Codex;
  private activeSwapRequests: Map<string, ActiveSwapRequest> = new Map();
  private swapSubjects: Map<string, Subject<PrebuildSwapResponse>> = new Map();
  private swapRegistry: Map<string, PrebuildSwapResponse & { transaction: Transaction }> = new Map();

  private readonly REGISTRY_TIMEOUT = 5 * 60 * 1000; // 5 minutes in milliseconds

  /**
   * Creates a new instance of TubService
   * @param gqlClient - GraphQL client for database operations
   * @param privy - Privy client for authentication
   * @param octane - OctaneService instance for transaction handling
   */
  constructor(gqlClient: GqlClient["db"], privy: PrivyClient, codexSdk: Codex, octane: OctaneService) {
    this.gql = gqlClient;
    this.octane = octane;
    this.privy = privy;
    this.codexSdk = codexSdk;
    
    // Start cleanup interval
    setInterval(() => this.cleanupRegistry(), 60 * 1000); // Run cleanup every minute
  }

  private cleanupRegistry() {
    const now = Date.now();
    for (const [key, value] of this.swapRegistry.entries()) {
      if (now - value.timestamp > this.REGISTRY_TIMEOUT) {
        this.swapRegistry.delete(key);
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
    } catch (e: any) {
      throw new Error(`Invalid JWT: ${e.message}`);
    }
  };

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

  // !! TODO: implement this after transaction success
  async sellToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.SellTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  // !! TODO: implement this after transaction success
  async buyToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.BuyTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }
    return result.data;
  }

  async airdropNativeToUser(jwtToken: string, amount: bigint) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
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

  async requestCodexToken(expiration?: number) {
    expiration = expiration ?? 3600 * 1000;
    const res = await this.codexSdk.mutations.createApiTokens({
      input: { expiresIn: expiration },
    });

    const token = res.createApiTokens[0]?.token;
    const expiry = res.createApiTokens[0]?.expiresTimeString;
    if (!token || !expiry) {
      throw new Error("Failed to create Codex API token");
    }

    return { token: `Bearer ${token}`, expiry };
  }

  /**
   * Builds a swap transaction for exchanging tokens
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
  async fetchSwap(jwtToken: string, request: UserPrebuildSwapRequest): Promise<PrebuildSwapResponse> {
    const userId = await this.verifyJWT(jwtToken);

    const userWallet = await this.getUserWallet(userId);
    if (!userWallet) {
      throw new Error("User does not have a wallet registered with Privy");
    }

    const userPublicKey = new PublicKey(userWallet);
    
    const derivedAccounts = await this.deriveTokenAccounts(
      userPublicKey,
      request.buyTokenId,
      request.sellTokenId
    );
    
    const activeRequest: ActiveSwapRequest = {
      ...request,
      ...derivedAccounts,
      userPublicKey
    };

    const response = await this.buildSwapResponse(activeRequest);
    if (!response) {
      throw new Error("Failed to build swap response");
    }

    console.log(`[fetchSwap] Successfully built swap for user ${userId}`);
    return response;
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
      sellQuantity: 1e6 // 1 USDC
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
    const derivedAccounts = await this.deriveTokenAccounts(
      userPublicKey,
      request.buyTokenId,
      request.sellTokenId
    );
    
    // Store the enhanced request
    this.activeSwapRequests.set(userId, {
      ...request,
      ...derivedAccounts,
      userPublicKey
    });
    
    if (!this.swapSubjects.has(userId)) {
      const subject = new Subject<PrebuildSwapResponse>();
      this.swapSubjects.set(userId, subject);

      // Create 1-second interval stream
      interval(1000)
        .pipe(
          switchMap(async () => {
            const currentRequest = this.activeSwapRequests.get(userId);
            if (!currentRequest) return null;
            return this.buildSwapResponse(currentRequest);
          })
        )
        .subscribe((response: PrebuildSwapResponse | null) => {
          if (response) {
            subject.next(response);
          }
        });
    }

    return this.swapSubjects.get(userId)!;
  }

  /**
   * Updates parameters for an active swap request
   * @param jwtToken - The user's JWT token
   * @param updates - New parameters to update
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
        ? await this.deriveTokenAccounts(
            userPublicKey,
            updates.buyTokenId ?? current.buyTokenId,
            updates.sellTokenId ?? current.sellTokenId
          )
        : {};

      const updated = { ...current, ...updates, ...derivedAccounts };
      this.activeSwapRequests.set(userId, updated);
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
    const subject = this.swapSubjects.get(userId);
    if (subject) {
      subject.complete();
      this.swapSubjects.delete(userId);
    } else {
      throw new Error(`[stopSwapStream] No active stream found for user ${userId}`);
    }
  }

  /**
   * Validates, signs, and sends a transaction with user and fee payer signatures
   * @param jwtToken - The user's JWT token
   * @param userSignature - The user's signature for the transaction
   * @param base64Transaction - The base64-encoded transaction (before signing) to submit. Came from swapStream
   * @returns Object containing the transaction signature
   * @throws Error if transaction processing fails
   */
  async signAndSendTransaction(jwtToken: string, userSignature: string, base64Transaction: string) {
    try {
      const userId = await this.verifyJWT(jwtToken);

      const registryEntry = this.swapRegistry.get(base64Transaction);
      if (!registryEntry) {
        throw new Error("Transaction not found in registry");
      }
      
      const walletAddress = await this.getUserWallet(userId);
      if (!walletAddress) {
        throw new Error("User does not have a wallet registered with Privy");
      }
      const userPublicKey = new PublicKey(walletAddress);

      // Create a new transaction from the registry entry
      const transaction = Transaction.from(Buffer.from(base64Transaction, 'base64'));
      
      // Add user signature
      const userSignatureBytes = Buffer.from(bs58.decode(userSignature));
      transaction.addSignature(userPublicKey, userSignatureBytes);

      // In test environment, skip token fee validation
      // !! TODO: Currently set to always be true. There's an error with Octane using an old RPC Method that no longer exists.
      // Once fixed, this if/then can be removed.
      if (true) {
        const feePayerSignature = await this.octane.signTransactionWithoutTokenFee(transaction);
        const feePayerSignatureBytes = Buffer.from(bs58.decode(feePayerSignature));
        transaction.addSignature(this.octane.getSettings().feePayerPublicKey, feePayerSignatureBytes);
      } else {
        let feePayerSignature;
        if (registryEntry.hasFee) {
          feePayerSignature = await this.octane.signTransactionWithTokenFee(
            transaction,
            true, // buyWithUSDCBool
            new PublicKey(USDC_MAINNET_PUBLIC_KEY.toString()), // USDC
            6 // tokenDecimals
          );
        } else {
          feePayerSignature = await this.octane.signTransactionWithoutTokenFee(transaction);
        }

        const feePayerSignatureBytes = Buffer.from(bs58.decode(feePayerSignature));
        transaction.addSignature(this.octane.getSettings().feePayerPublicKey, feePayerSignatureBytes);
      }

      // Send the fully signed transaction
      const txid = await this.octane.getSettings().connection.sendRawTransaction(
        transaction.serialize(),
        { skipPreflight: false }
      );
      console.log(`[signAndSendTransaction] Transaction sent with ID: ${txid}`);

      // Wait for confirmation using polling
      const confirmation = await this.octane.getSettings().connection.confirmTransaction(
        {
          signature: txid,
          blockhash: transaction.recentBlockhash!,
          lastValidBlockHeight: transaction.lastValidBlockHeight!
        },
        'processed'
      );
      console.log(`[signAndSendTransaction] Transaction confirmed:`, confirmation);
      
      if (confirmation.value.err) {
        throw new Error(`Transaction failed: ${confirmation.value.err}`);
      }

      // Clean up registry
      this.swapRegistry.delete(base64Transaction);
      console.log(`[signAndSendTransaction] Transaction completed successfully`);

      return { signature: txid };

    } catch (error) {
      if (error instanceof SendTransactionError) {
        const logs = error.logs?.join('\n') ?? 'No logs available';
        let details = 'No additional details';
        
        try {
          // Get the logs before creating the error message
          details = (await error.getLogs(this.octane.getSettings().connection)).join('\n');
          
          console.error("[signAndSendTransaction] Transaction failed:", {
            message: error.message,
            logs,
            details: Array.isArray(details) ? details.join('\n') : details,
          });

          throw new Error(
            `Transaction failed: ${error.message}\n` +
            `Logs:\n${logs}\n` +
            `Details:\n${Array.isArray(details) ? details.join('\n') : details}`
          );
        } catch (logError) {
          console.error("[signAndSendTransaction] Error getting detailed logs:", logError);
          throw new Error(`Transaction failed: ${error.message}\nLogs:\n${logs}`);
        }
      }
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
  private async deriveTokenAccounts(
    userPublicKey: PublicKey,
    buyTokenId: string,
    sellTokenId: string
  ): Promise<{ buyTokenAccount?: PublicKey; sellTokenAccount?: PublicKey }> {
    const accounts: { buyTokenAccount?: PublicKey; sellTokenAccount?: PublicKey } = {};

    accounts.buyTokenAccount = await getAssociatedTokenAddress(
      new PublicKey(buyTokenId),
        userPublicKey,
        false
    );

    accounts.sellTokenAccount = await getAssociatedTokenAddress(
      new PublicKey(sellTokenId),
        userPublicKey,
        false
    );
    
    return accounts;
  }

  private async buildSwapResponse(
    request: ActiveSwapRequest
  ): Promise<PrebuildSwapResponse | null> {
    // console.log("[buildSwapResponse] Starting with request:", {
    //   sellQuantity: request.sellQuantity,
    //   sellTokenId: request.sellTokenId,
    //   buyTokenId: request.buyTokenId,
    //   userPublicKey: request.userPublicKey.toString()
    // });

    if (!request.sellTokenAccount) return null;

    // if sell token is either USDC Devnet or Mainnet, use the buy fee amount. otherwise use 0
    const feeAmount = request.sellTokenId === USDC_DEV_PUBLIC_KEY.toString() || 
      request.sellTokenId === USDC_MAINNET_PUBLIC_KEY.toString()
        ? this.octane.getSettings().buyFee
        : 0;

    // Check if this is a USDC sell transaction
    const isUSDCSell = request.sellTokenId === USDC_MAINNET_PUBLIC_KEY.toString() || 
                       request.sellTokenId === USDC_DEV_PUBLIC_KEY.toString();

    let transaction: Transaction | null = null;
    try {
      if (feeAmount === 0) {
        // console.log("[buildSwapResponse] No fee, getting swap instructions");
        const swapInstructions = await this.octane.getQuoteAndSwapInstructions({
          inputMint: request.sellTokenId,
          outputMint: request.buyTokenId,
          amount: request.sellQuantity,
          slippageBps: 10,
          onlyDirectRoutes: false,
          asLegacyTransaction: true, // Set to true for USDC sells
        }, request.userPublicKey);

        // console.log("[buildSwapResponse] Got swap instructions:", {
        //   hasSetupInstructions: !!swapInstructions?.setupInstructions?.length,
        //   hasSwapInstruction: !!swapInstructions?.swapInstruction,
        //   hasCleanupInstruction: !!swapInstructions?.cleanupInstruction
        // });

        if (!swapInstructions?.swapInstruction) {
          throw new Error("No swap instruction received");
        }

        transaction = await this.octane.buildCompleteSwap(swapInstructions, null);
      } else {
        const feeOptions = {
          sourceAccount: request.sellTokenAccount,
          destinationAccount: this.octane.getSettings().tradeFeeRecipient,
          amount: Number((BigInt(feeAmount) * BigInt(request.sellQuantity) / 10000n)),
        };

        const feeTransferInstruction = createTransferInstruction(
          feeOptions.sourceAccount,
          feeOptions.destinationAccount,
          request.userPublicKey,
          feeOptions.amount,
        );

        const swapInstructions = await this.octane.getQuoteAndSwapInstructions({
          inputMint: request.sellTokenId,
          outputMint: request.buyTokenId,
          amount: request.sellQuantity - feeOptions.amount,
          slippageBps: 10,
          onlyDirectRoutes: true,
          asLegacyTransaction: true, // Set to true for USDC sells
        }, request.userPublicKey);

        // console.log("[buildSwapResponse] Got swap instructions:", {
        //   hasSetupInstructions: !!swapInstructions?.setupInstructions?.length,
        //   hasSwapInstruction: !!swapInstructions?.swapInstruction,
        //   hasCleanupInstruction: !!swapInstructions?.cleanupInstruction
        // });

        if (!swapInstructions?.swapInstruction) {
          throw new Error("No swap instruction received");
        }

        transaction = await this.octane.buildCompleteSwap(swapInstructions, feeTransferInstruction);
      }

      if (!transaction) {
        throw new Error("Failed to build transaction");
      }

      // Get fresh blockhash right before returning to user
      const { blockhash, lastValidBlockHeight } = await this.octane.getSettings().connection.getLatestBlockhash();
      transaction.recentBlockhash = blockhash;
      transaction.lastValidBlockHeight = lastValidBlockHeight;

      // console.log("[buildSwapResponse] Built transaction:", {
      //   hasInstructions: transaction.instructions.length > 0,
      //   instructionCount: transaction.instructions.length,
      //   hasFeePayer: !!transaction.feePayer,
      //   recentBlockhash: transaction.recentBlockhash
      // });

      const response: PrebuildSwapResponse = {
        transactionBase64: Buffer.from(transaction.serialize({ verifySignatures: false })).toString('base64'),
        ...request,
        hasFee: feeAmount > 0,
        timestamp: Date.now()
      };
      
      // Store in registry with fee information
      this.swapRegistry.set(
        response.transactionBase64,
        { ...response, transaction }
      );
      
      return response;

    } catch (error) {
      console.error("[buildSwapResponse] Error:", error);
      throw error;
    }
  }
}
