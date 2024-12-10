import { Connection, Keypair, PublicKey, VersionedTransaction } from "@solana/web3.js";
import { GqlClient } from "@tub/gql";
import { PrivyClient } from "@privy-io/server-auth";
import { Codex } from "@codex-data/sdk";
import { JupiterService } from "./JupiterService";
import { SwapService } from "./SwapService";
import { TransactionService } from "./TransactionService";
import { FeeService } from "./FeeService";
import { AuthService } from "./AuthService";
import { AnalyticsService } from "./AnalyticsService";
import { CodexService } from "./CodexService";
import { TransferService } from "./TransferService";
import { env } from "../../bin/tub-server";
import {
  UserPrebuildSwapRequest,
  PrebuildSwapResponse,
  PrebuildSignedSwapResponse,
  ClientEvent,
  TransferRequest,
  SignedTransfer,
} from "../types";
import { deriveTokenAccounts } from "../utils/tokenAccounts";
import { SOL_MAINNET_PUBLIC_KEY, USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";
import bs58 from "bs58";

/**
 * Service class handling token trading, swaps, and user operations
 */
export class TubService {
  private connection: Connection;
  private swapService: SwapService;
  private authService: AuthService;
  private transactionService: TransactionService;
  private feeService: FeeService;
  private analyticsService: AnalyticsService;
  private codexService: CodexService;
  private transferService: TransferService;

  /**
   * Creates a new instance of TubService
   * @param gqlClient - GraphQL client for database operations
   * @param privy - Privy client for authentication
   * @param jupiter - JupiterService instance for transaction handling
   */
  constructor(gqlClient: GqlClient["db"], privy: PrivyClient, codexSdk: Codex, jupiter: JupiterService) {
    this.connection = new Connection(env.QUICKNODE_MAINNET_URL);
    this.authService = new AuthService(privy);

    // Initialize fee payer
    const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));
    const feePayerPublicKey = feePayerKeypair.publicKey;

    // Initialize services
    this.transactionService = new TransactionService(this.connection, feePayerKeypair, feePayerPublicKey);

    this.feeService = new FeeService({
      buyFee: env.OCTANE_BUY_FEE,
      sellFee: env.OCTANE_SELL_FEE,
      minTradeSize: env.OCTANE_MIN_TRADE_SIZE,
      feePayerPublicKey: feePayerPublicKey,
      tradeFeeRecipient: new PublicKey(env.OCTANE_TRADE_FEE_RECIPIENT),
    });

    this.swapService = new SwapService(jupiter, this.transactionService, this.feeService);

    this.analyticsService = new AnalyticsService(gqlClient);
    this.codexService = new CodexService(codexSdk);
    this.transferService = new TransferService(this.connection, feePayerKeypair);
  }

  // Status endpoint
  getStatus(): { status: number } {
    return { status: 200 };
  }

  // Analytics methods
  async recordClientEvent(event: ClientEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordClientEvent(event, walletPublicKey.toBase58());
  }

  // Codex methods
  async requestCodexToken(expiration?: number) {
    return this.codexService.requestToken(expiration);
  }

  // Transfer methods
  async getSignedTransfer(jwtToken: string, request: TransferRequest): Promise<SignedTransfer> {
    await this.authService.getUserContext(jwtToken); // Verify user is authenticated
    return this.transferService.getSignedTransfer(request);
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
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const { buyTokenAccount, sellTokenAccount } = deriveTokenAccounts(
      walletPublicKey,
      request.buyTokenId,
      request.sellTokenId,
    );

    const activeRequest = {
      ...request,
      buyTokenAccount,
      sellTokenAccount,
      userPublicKey: walletPublicKey,
    };

    try {
      const response = await this.swapService.buildSwapResponse(activeRequest);
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
    const registryEntry = this.swapService.getMessageFromRegistry(fetchSwapResponse.transactionMessageBase64);
    if (!registryEntry) {
      throw new Error("Transaction not found in registry");
    }
    const message = registryEntry.message;

    const transaction = new VersionedTransaction(message);

    // remove transaction from registry
    this.swapService.deleteMessageFromRegistry(fetchSwapResponse.transactionMessageBase64);

    const feePayerSignature = await this.transactionService.signTransaction(transaction);

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
    const { userId, walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const { buyTokenAccount, sellTokenAccount } = deriveTokenAccounts(
      walletPublicKey,
      request.buyTokenId,
      request.sellTokenId,
    );

    const activeRequest = {
      ...request,
      buyTokenAccount,
      sellTokenAccount,
      userPublicKey: walletPublicKey,
    };

    return this.swapService.startSwapStream(userId, activeRequest);
  }

  async stopSwapStream(jwtToken: string) {
    const { userId } = await this.authService.getUserContext(jwtToken);
    await this.swapService.stopSwapStream(userId);
  }

  async signAndSendTransaction(jwtToken: string, userSignature: string, base64TransactionMessage: string) {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.swapService.signAndSendTransaction(walletPublicKey, userSignature, base64TransactionMessage);
  }

  /**
   * Updates parameters for an active swap request and returns a new transaction
   * @param jwtToken - The user's JWT token
   * @param request - The swap request parameters
   * @returns New swap transaction with updated parameters
   * @throws Error If no active request exists or if building new transaction fails
   *
   * @remarks
   * The new transaction will be stored in the registry for 5 minutes.
   *
   * @example
   * // Update sell quantity to 2 USDC
   * const response = await tubService.updateSwapRequest(jwt, {
   *   sellQuantity: 2e6 // Other tokens may have 1e9 standard
   * });
   */
  async updateSwapRequest(jwtToken: string, request: UserPrebuildSwapRequest) {
    const { userId, walletPublicKey } = await this.authService.getUserContext(jwtToken);

    if (!this.swapService.hasActiveStream(userId)) {
      throw new Error("No active swap stream found to update");
    }

    // Get a new swap response with updated parameters
    const response = await this.fetchSwap(jwtToken, request);

    // Derive token accounts for the new request
    const { buyTokenAccount, sellTokenAccount } = deriveTokenAccounts(
      walletPublicKey,
      request.buyTokenId,
      request.sellTokenId,
    );

    const updatedRequest = {
      ...request,
      buyTokenAccount,
      sellTokenAccount,
      userPublicKey: walletPublicKey,
    };

    this.swapService.updateActiveRequest(userId, updatedRequest);
    return response;
  }
}
