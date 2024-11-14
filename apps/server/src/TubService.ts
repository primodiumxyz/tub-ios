import { PrivyClient, WalletWithMetadata } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";
import { OctaneService } from "./OctaneService";
import { Subject, interval, switchMap } from 'rxjs';
import { PublicKey, Transaction } from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddress } from "@solana/spl-token";
import { UserPrebuildSwapRequest } from "../types/PrebuildSwapRequest";

config({ path: "../../.env" });

const USDC_DEV_PUBLIC_KEY = new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"); // The address of the USDC token on Solana Devnet
const USDC_MAINNET_PUBLIC_KEY = new PublicKey("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"); // The address of the USDC token on Solana Mainnet

// Internal type that extends UserPrebuildSwapRequest with derived addresses
type ActiveSwapRequest = UserPrebuildSwapRequest & {
  buyTokenAccount?: PublicKey;
  sellTokenAccount?: PublicKey;
};

export class TubService {
  private gql: GqlClient["db"];
  private octane: OctaneService;
  private privy: PrivyClient;
  private activeSwapRequests: Map<string, ActiveSwapRequest> = new Map();
  private swapSubjects: Map<string, Subject<Transaction>> = new Map();
  private swapRegistry: Map<string, { 
    hasFee: boolean, 
    transaction: Transaction,
    timestamp: number 
  }> = new Map();

  private readonly REGISTRY_TIMEOUT = 5 * 60 * 1000; // 5 minutes in milliseconds

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient, octane: OctaneService) {
    this.gql = gqlClient;
    this.octane = octane;
    this.privy = privy;
    
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

  private verifyJWT = async (token: string) => {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      return verifiedClaims.userId;
    } catch (e: any) {
      throw new Error(`Invalid JWT: ${e.message}`);
    }
  };

  private async getUserWallet(userId: string) {
    const user = await this.privy.getUserById(userId);

    const solanaWallet = user.linkedAccounts.find(
      (account) => account.type === "wallet" && account.chainType === "solana",
    ) as WalletWithMetadata | undefined;
    console.log(solanaWallet);
    return solanaWallet?.address;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  // !! TODO: implement this after transaction success
  async sellToken(jwtToken: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.SellTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  // !! TODO: implement this after transaction success
  async buyToken(jwtToken: string, tokenId: string, amount: bigint, overridePrice?: bigint) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.BuyTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice?.toString(),
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

  async startSwapStream(userId: string, request: UserPrebuildSwapRequest) {
    // Derive token accounts
    const derivedAccounts = await this.deriveTokenAccounts(
      request.userPublicKey,
      request.buyTokenId,
      request.sellTokenId
    );
    
    // Store the enhanced request
    this.activeSwapRequests.set(userId, {
      ...request,
      ...derivedAccounts
    });
    
    if (!this.swapSubjects.has(userId)) {
      const subject = new Subject<Transaction>();
      this.swapSubjects.set(userId, subject);

      // Create 1-second interval stream
      interval(1000)
        .pipe(
          switchMap(async () => {
            const currentRequest = this.activeSwapRequests.get(userId);
            if (!currentRequest || !currentRequest.sellTokenAccount) return null;

            // if sell token is either USDC Devnet or Mainnet, use the buy fee amount. otherwise use 0
            const feeAmount = currentRequest.sellTokenId === USDC_DEV_PUBLIC_KEY.toString() || currentRequest.sellTokenId === USDC_MAINNET_PUBLIC_KEY.toString()
              ? this.octane.getSettings().buyFee
              : 0;

            let transaction: Transaction | null = null;
            if (feeAmount === 0) {
              const swapInstructions = await this.octane.getQuoteAndSwapInstructions({
                inputMint: currentRequest.sellTokenId!,
                outputMint: currentRequest.buyTokenId!,
                amount: currentRequest.sellQuantity || 0,
                autoSlippage: true,
                minimizeSlippage: true,
                onlyDirectRoutes: false,
                asLegacyTransaction: false,
              }, currentRequest.userPublicKey);
              transaction = await this.octane.buildCompleteSwap(swapInstructions, null);
            } else {
              const feeOptions = {
                sourceAccount: currentRequest.sellTokenAccount,
                  destinationAccount: this.octane.getSettings().tradeFeeRecipient,
                  amount: feeAmount,
                };

              const feeTransferInstruction = createTransferInstruction(
                  feeOptions.sourceAccount,
                  feeOptions.destinationAccount,
                  currentRequest.userPublicKey,
                  feeOptions.amount,
              );

              const swapInstructions = await this.octane.getQuoteAndSwapInstructions({
                inputMint: currentRequest.sellTokenId!,
                outputMint: currentRequest.buyTokenId!,
                amount: currentRequest.sellQuantity || 0,
                autoSlippage: true,
                minimizeSlippage: true,
                onlyDirectRoutes: false,
                asLegacyTransaction: false,
              }, currentRequest.userPublicKey);
              transaction = await this.octane.buildCompleteSwap(swapInstructions, feeTransferInstruction);
            }

            if (transaction) {
              const transactionBase64 = Buffer.from(
                transaction.serialize()
              ).toString('base64');
              
              // Store in registry with fee information
              this.swapRegistry.set(
                transactionBase64,
                { 
                  hasFee: feeAmount > 0, 
                  transaction,
                  timestamp: Date.now()
                }
              );
            }

            return transaction;
          })
        )
        .subscribe((transaction: Transaction | null) => {
          if (transaction) {
            subject.next(transaction);
          }
        });
    }

    return this.swapSubjects.get(userId)!;
  }

  async updateSwapRequest(userId: string, updates: Partial<UserPrebuildSwapRequest>) {
    const current = this.activeSwapRequests.get(userId);
    if (current) {
      // Re-derive accounts if tokens changed
      const needsNewDerivedAccounts = 
        (updates.buyTokenId && updates.buyTokenId !== current.buyTokenId) ||
        (updates.sellTokenId && updates.sellTokenId !== current.sellTokenId);

      const derivedAccounts = needsNewDerivedAccounts 
        ? await this.deriveTokenAccounts(
            current.userPublicKey,
            updates.buyTokenId ?? current.buyTokenId,
            updates.sellTokenId ?? current.sellTokenId
          )
        : {};

      this.activeSwapRequests.set(userId, { 
        ...current, 
        ...updates,
        ...derivedAccounts 
      });
    }
  }

  async stopSwapStream(userId: string) {
    this.activeSwapRequests.delete(userId);
    const subject = this.swapSubjects.get(userId);
    if (subject) {
      subject.complete();
      this.swapSubjects.delete(userId);
    }
  }

  async signAndSendTransaction(userId: string, userSignature: string, base64Transaction: string) {
    try {
      const registryEntry = this.swapRegistry.get(base64Transaction);
      if (!registryEntry) {
        throw new Error("Transaction not found in registry");
      }
      const transaction = registryEntry.transaction;
      const walletAddress = await this.getUserWallet(userId);
      if (!walletAddress) {
        throw new Error("User does not have a wallet registered with Privy");
      }
      const userPublicKey = new PublicKey(walletAddress);
      transaction.addSignature(userPublicKey, Buffer.from(userSignature));

      let feePayerSignature;
      if (registryEntry.hasFee) {
        feePayerSignature = await this.octane.signTransactionWithTokenFee(
          transaction,
          true, // buyWithUSDCBool
          USDC_MAINNET_PUBLIC_KEY,
          6 // tokenDecimals, note that other tokens besides USDC may have different decimals
        );
      } else {
        feePayerSignature = await this.octane.signTransactionWithoutTokenFee(transaction);
      }

      transaction.addSignature(this.octane.getSettings().feePayerPublicKey, Buffer.from(feePayerSignature));

      // Send the fully signed transaction with signature
      const txid = await this.octane.getSettings().connection.sendRawTransaction(
        transaction.serialize(),
        { skipPreflight: false }
      );

      // Wait for confirmation
      const confirmation = await this.octane.getSettings().connection.confirmTransaction(txid);
      
      if (confirmation.value.err) {
        throw new Error(`Transaction failed: ${confirmation.value.err}`);
      }

      // Clean up registry
      this.swapRegistry.delete(base64Transaction);

      return { signature: txid };

    } catch (error: unknown) {
      console.error("Error processing transaction:", error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      throw new Error(`Failed to process transaction: ${errorMessage}`);
    }
  }

  private async deriveTokenAccounts(
    userPublicKey: PublicKey,
    buyTokenId?: string,
    sellTokenId?: string
  ): Promise<{ buyTokenAccount?: PublicKey; sellTokenAccount?: PublicKey }> {
    const accounts: { buyTokenAccount?: PublicKey; sellTokenAccount?: PublicKey } = {};
    
    if (buyTokenId) {
      accounts.buyTokenAccount = await getAssociatedTokenAddress(
        new PublicKey(buyTokenId),
        userPublicKey,
        false
      );
    }
    
    if (sellTokenId) {
      accounts.sellTokenAccount = await getAssociatedTokenAddress(
        new PublicKey(sellTokenId),
        userPublicKey,
        false
      );
    }
    
    return accounts;
  }
}
