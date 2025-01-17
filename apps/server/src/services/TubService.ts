import { PrivyClient } from "@privy-io/server-auth";
import { getAccount, getAssociatedTokenAddressSync } from "@solana/spl-token";
import { Connection, Keypair, PublicKey, VersionedTransaction } from "@solana/web3.js";
import { GqlClient } from "@tub/gql";
import bs58 from "bs58";
import { env } from "../../bin/tub-server";
import { TOKEN_PROGRAM_PUBLIC_KEY, USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";
import { Config, ConfigService } from "../services/ConfigService";
import {
  AppDwellTimeEvent,
  LoadingTimeEvent,
  PrebuildSignedSwapResponse,
  PrebuildSwapResponse,
  SubmitSignedTransactionResponse,
  TokenDwellTimeEvent,
  TokenPurchaseOrSaleEvent,
  UserPrebuildSwapRequest,
  ActiveSwapRequest,
  TransactionType,
} from "../types";
import { config } from "../utils/config";
import { deriveTokenAccounts } from "../utils/tokenAccounts";
import { AnalyticsService } from "./AnalyticsService";
import { CronService } from "./CronService";
import { PushService } from "./ApplePushService";
import { AuthService } from "./AuthService";
import { FeeService } from "./FeeService";
import { JupiterService } from "./JupiterService";
import { SwapService } from "./SwapService";
import { TransactionService } from "./TransactionService";
import { TransferService } from "./TransferService";

/**
 * Service class handling token trading, swaps, and user operations
 */
export class TubService {
  private connection!: Connection;
  private swapService!: SwapService;
  private authService!: AuthService;
  private transactionService!: TransactionService;
  private feeService!: FeeService;
  private analyticsService!: AnalyticsService;
  private transferService!: TransferService;
  private pushService!: PushService;
  /**
   * Creates a new instance of TubService
   * @param gqlClient - GraphQL client for database operations
   * @param privy - Privy client for authentication
   * @param jupiterService - JupiterService instance for transaction handling
   */
  private constructor(
    private readonly gqlClient: GqlClient["db"],
    private readonly privy: PrivyClient,
    private readonly jupiterService: JupiterService,
  ) {}

  /**
   * Factory method to create a fully initialized TubService
   */
  static async create(
    gqlClient: GqlClient["db"],
    privy: PrivyClient,
    jupiterService: JupiterService,
  ): Promise<TubService> {
    const service = new TubService(gqlClient, privy, jupiterService);
    await service.initialize();
    return service;
  }

  private async initialize(): Promise<void> {
    // initialize connection
    this.connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`);

    // validate trade fee recipient
    const validatedTradeFeeRecipient = await this.validateTradeFeeRecipient();

    // initialize config service first since other services might need it
    await ConfigService.getInstance();

    // Initialize fee payer
    const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));

    this.authService = new AuthService(this.privy);
    this.transactionService = new TransactionService(this.connection, feePayerKeypair);
    this.feeService = new FeeService({
      tradeFeeRecipient: validatedTradeFeeRecipient,
    });
    this.swapService = new SwapService(this.jupiterService, this.transactionService, this.feeService);
    this.analyticsService = new AnalyticsService(this.gqlClient);
    this.transferService = new TransferService(this.connection, feePayerKeypair, this.transactionService);

    this.pushService = new PushService({ gqlClient: this.gqlClient });

    // Start periodic tasks
    new CronService(this.gqlClient).startPeriodicTasks();
  }

  /**
   * Validates that the trade fee recipient has a valid USDC ATA
   * @remarks
   * This method checks if the trade fee recipient is an initialized USDC ATA address. If not, checks that if the trade fee recipient is a pubkey address that has a valid USDC ATA.
   * @returns The public key of the trade fee recipient USDC ATA
   * @throws Error if the trade fee recipient does not have a valid USDC ATA
   */
  private async validateTradeFeeRecipient(): Promise<PublicKey> {
    const cfg = await config();
    let tradeFeeRecipientUsdcAtaAddress = new PublicKey(cfg.TRADE_FEE_RECIPIENT);

    try {
      // Check if env is a USDC ATA address
      await getAccount(this.connection, tradeFeeRecipientUsdcAtaAddress);
      return tradeFeeRecipientUsdcAtaAddress;
    } catch {
      try {
        // Check if env is a pubkey address that has a valid USDC ATA
        tradeFeeRecipientUsdcAtaAddress = getAssociatedTokenAddressSync(
          USDC_MAINNET_PUBLIC_KEY,
          new PublicKey(cfg.TRADE_FEE_RECIPIENT),
        );
        await getAccount(this.connection, tradeFeeRecipientUsdcAtaAddress);
      } catch {
        throw new Error("Trade fee recipient not a valid USDC ATA");
      }
    }

    return tradeFeeRecipientUsdcAtaAddress;
  }

  // Status endpoint
  getStatus(): { status: number } {
    return { status: 200 };
  }

  // Analytics methods
  async recordTokenPurchase(event: TokenPurchaseOrSaleEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordTokenPurchase(event, walletPublicKey.toBase58());
  }

  async recordTokenSale(event: TokenPurchaseOrSaleEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordTokenSale(event, walletPublicKey.toBase58());
  }

  async recordLoadingTime(event: LoadingTimeEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordLoadingTime(event, walletPublicKey.toBase58());
  }

  async recordAppDwellTime(event: AppDwellTimeEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordAppDwellTime(event, walletPublicKey.toBase58());
  }

  async recordTokenDwellTime(event: TokenDwellTimeEvent, jwtToken: string): Promise<string> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    return this.analyticsService.recordTokenDwellTime(event, walletPublicKey.toBase58());
  }

  // Price methods
  async getSolUsdPrice(): Promise<number | undefined> {
    return this.jupiterService.getSolUsdPrice();
  }

  subscribeSolPrice(callback: (price: number) => void): () => void {
    return this.jupiterService.subscribeSolPrice(callback);
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

    const cfg = await config();
    const response = await this.buildSwapResponseWithRebuild(activeRequest, cfg, 0);
    return response;
  }

  async buildSwapResponseWithRebuild(
    activeRequest: ActiveSwapRequest,
    cfg: Config,
    priorBuildAttempts: number = 0,
  ): Promise<PrebuildSwapResponse> {
    for (let buildAttempt = priorBuildAttempts + 1; buildAttempt <= cfg.MAX_BUILD_ATTEMPTS; buildAttempt++) {
      console.log("Building swap response attempt " + buildAttempt);
      try {
        const response = await this.swapService.buildSwapResponse(activeRequest, cfg, buildAttempt);
        return response;
      } catch (error) {
        console.log("Failed to build swap response: ", error);
        // if build attempt is maxed out or if user has set slippage, throw error
        if (buildAttempt >= cfg.MAX_BUILD_ATTEMPTS || activeRequest.slippageBps !== undefined) {
          throw new Error("Failed to build swap response: " + error);
        }
      }
    }
    throw new Error("Failed to build swap response");
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

  async signAndSendTransaction(
    jwtToken: string,
    userSignature: string,
    base64TransactionMessage: string,
  ): Promise<SubmitSignedTransactionResponse> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);
    const entry = this.transactionService.getRegisteredTransaction(base64TransactionMessage);
    if (!entry) {
      throw new Error("Transaction not found in registry");
    }
    const cfg = await config();

    try {
      const response = this.transactionService.signAndSendTransaction(walletPublicKey, userSignature, entry, cfg);
      return response;
    } catch (error) {
      console.log("Tx send failed: " + JSON.stringify(error));

      // don't rebuild transfer swaps
      if (entry.transactionType === TransactionType.TRANSFER) {
        throw new Error(JSON.stringify(error));
      }

      // TODO: error interpretation

      // don't rebuild if slippage is not auto
      if (entry.buildAttempts + 1 >= cfg.MAX_BUILD_ATTEMPTS || !entry.autoSlippage) {
        throw new Error(JSON.stringify(error));
      }

      // rebuild
      if (!this.swapService) {
        throw new Error("SwapService is not set");
      }
      if (!entry.activeSwapRequest) {
        throw new Error("ActiveSwapRequest is not set");
      }
      if (!entry.cfg) {
        throw new Error("Config is not set");
      }
      this.swapService.deleteMessageFromRegistry(base64TransactionMessage);
      const rebuiltSwapResponse = await this.buildSwapResponseWithRebuild(
        entry.activeSwapRequest,
        entry.cfg,
        entry.buildAttempts,
      );
      return { responseType: "rebuild", rebuild: rebuiltSwapResponse };
    }
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

  async getBalance(jwtToken: string): Promise<{ balance: number }> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const balance = await this.connection.getBalance(walletPublicKey, "processed");
    return { balance };
  }

  async getAllTokenBalances(
    jwtToken: string,
  ): Promise<{ tokenBalances: Array<{ mint: string; balanceToken: number }> }> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const tokenAccounts = await this.connection.getParsedTokenAccountsByOwner(
      walletPublicKey,
      { programId: TOKEN_PROGRAM_PUBLIC_KEY },
      "processed",
    );

    const tokenBalances = tokenAccounts.value.map((account) => ({
      mint: account.account.data.parsed.info.mint,
      balanceToken: Math.round(Number(account.account.data.parsed.info.tokenAmount.amount)),
    }));
    return { tokenBalances };
  }

  async getTokenBalance(jwtToken: string, tokenMint: string): Promise<{ balance: number }> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const tokenAccounts = await this.connection.getParsedTokenAccountsByOwner(
      walletPublicKey,
      { mint: new PublicKey(tokenMint) },
      "processed",
    );

    if (tokenAccounts.value.length === 0 || !tokenAccounts.value[0]?.account.data.parsed.info.tokenAmount.amount)
      return { balance: 0 };

    const balance = Number(tokenAccounts.value[0].account.data.parsed.info.tokenAmount.amount);
    return { balance };
  }

  /**
   * Creates a transaction for transferring USDC
   */
  async fetchTransferTx(
    jwtToken: string,
    request: {
      toAddress: string;
      amount: string;
      tokenId: string;
    },
  ): Promise<{ transactionMessageBase64: string }> {
    const { walletPublicKey } = await this.authService.getUserContext(jwtToken);

    const transferRequest = {
      fromAddress: walletPublicKey.toBase58(),
      toAddress: request.toAddress,
      amount: BigInt(request.amount),
      tokenId: request.tokenId,
    };

    // Get the transfer transaction from the transfer service
    return await this.transferService.getTransfer(transferRequest);
  }

  /* -------------------------------------------------------------------------- */
  /*                             Push Notifications                             */
  /* -------------------------------------------------------------------------- */

  async startLiveActivity(
    jwtToken: string,
    input: { tokenMint: string; tokenPriceUsd: string; deviceToken: string; pushToken: string },
  ) {
    const { userId } = await this.authService.getUserContext(jwtToken);
    return this.pushService.startLiveActivity(userId, input);
  }

  async stopLiveActivity(jwtToken: string) {
    const { userId } = await this.authService.getUserContext(jwtToken);
    return this.pushService.stopLiveActivity(userId);
  }
}
