import { Connection, Keypair, PublicKey, Transaction, TransactionInstruction } from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@primodiumxyz/octane-core";
import { QuoteGetRequest, QuoteResponse, SwapInstructionsPostRequest, SwapInstructionsResponse } from '@jup-ag/api';
import { Wallet } from "@coral-xyz/anchor";
import bs58 from "bs58";
import type { Cache } from 'cache-manager';
import { DefaultApi } from "@jup-ag/api";

// const testParams: QuoteGetRequest = {
//     inputMint: "So11111111111111111111111111111111111111112",
//     outputMint: "EKpQGSJtjMFqKZ9KQanSqYXRcF8fBopzLHYxdM65zcjm", // $WIF
//     amount: 100000000, // 0.1 SOL
//     autoSlippage: true,
//     autoSlippageCollisionUsdValue: 1_000,
//     maxAutoSlippageBps: 1000, // 10%
//     minimizeSlippage: true,
//     onlyDirectRoutes: false,
//     asLegacyTransaction: false,
// };

export type OctaneSettings = {
  feePayerPublicKey: PublicKey;
  tradeFeeRecipient: PublicKey;
  buyFee: number;
  sellFee: number;
  minTradeSize: number;
  connection: Connection;
  jupiterQuoteApi: DefaultApi;
};

/**
 * Service handling Solana transaction building and signing with Jupiter integration
 */
export class OctaneService {
  /**
   * Creates a new instance of OctaneService
   * @param connection - Solana RPC connection
   * @param jupiterQuoteApi - Jupiter API client
   * @param feePayerKeypair - Keypair for the fee payer
   * @param tradeFeeRecipient - Public key to receive (USDC) trade fees
   * @param buyFee - Fee amount for buy operations
   * @param sellFee - Fee amount for sell operations (not utilized yet, should be 0)
   * @param minTradeSize - Minimum allowed trade size
   * @param cache - Cache manager instance
   */
  constructor(
    private connection: Connection,
    private jupiterQuoteApi: DefaultApi,
    private feePayerKeypair: Keypair,
    private tradeFeeRecipient: PublicKey,
    private buyFee: number,
    private sellFee: number,
    private minTradeSize: number,
    private cache: Cache
  ) {}

  getSettings(): OctaneSettings {
    return {
      feePayerPublicKey: this.feePayerKeypair.publicKey,
      tradeFeeRecipient: this.tradeFeeRecipient,
      buyFee: this.buyFee,
      sellFee: this.sellFee,
      minTradeSize: this.minTradeSize,
      connection: this.connection,
      jupiterQuoteApi: this.jupiterQuoteApi,
    };
  }

  /**
   * Gets a quote for a token swap from Jupiter
   * @param params - Quote request parameters
   * @returns Quote response from Jupiter
   * @throws Error if quote cannot be obtained
   */
  async getQuote(params: QuoteGetRequest) {
    // basic params
    // const params: QuoteGetRequest = {
    //   inputMint: "J1toso1uCk3RLmjorhTtrVwY9HJ7X8V9yYac6Y7kGCPn",
    //   outputMint: "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So",
    //   amount: 35281,
    //   slippageBps: 50,
    //   onlyDirectRoutes: false,
    //   asLegacyTransaction: false,
    // }
  
    // // auto slippage w/ minimizeSlippage params
    // const params: QuoteGetRequest = {
    //   inputMint: "So11111111111111111111111111111111111111112",
    //   outputMint: "EKpQGSJtjMFqKZ9KQanSqYXRcF8fBopzLHYxdM65zcjm", // $WIF
    //   amount: 100000000, // 0.1 SOL
    //   autoSlippage: true,
    //   autoSlippageCollisionUsdValue: 1_000,
    //   maxAutoSlippageBps: 1000, // 10%
    //   minimizeSlippage: true,
    //   onlyDirectRoutes: false,
    //   asLegacyTransaction: false,
    // };
  
    // get quote
    const quote = await this.jupiterQuoteApi.quoteGet(params);
  
    if (!quote) {
      throw new Error("unable to quote");
    }
    return quote;
  }
  
  async getSwapObj(wallet: Wallet, quote: QuoteResponse) {
    // Get serialized transaction
    const swapObj = await this.jupiterQuoteApi.swapPost({
      swapRequest: {
        quoteResponse: quote,
        userPublicKey: wallet.publicKey.toBase58(),
        dynamicComputeUnitLimit: true,
        prioritizationFeeLamports: "auto",
      },
    });
    return swapObj;
  }
  
  async flowQuote(quoteParams: QuoteGetRequest) {
    const quote = await this.getQuote(quoteParams);
    console.dir(quote, { depth: null });
  }
  
  /**
   * Gets swap instructions for a quoted trade
   * @param quoteAndSwapParams - Parameters for quote and swap
   * @param userPublicKey - User's public key
   * @returns Swap instructions from Jupiter
   */
  async getQuoteAndSwapInstructions(quoteAndSwapParams: QuoteGetRequest, userPublicKey: PublicKey) {  
    const quote = await this.getQuote(quoteAndSwapParams);
    console.dir(quote, { depth: null });

    const swapInstructionsRequest: SwapInstructionsPostRequest = {
        "swapRequest": {
            "userPublicKey": userPublicKey.toBase58(),
            "wrapAndUnwrapSol": true,
            "useSharedAccounts": true,
            "computeUnitPriceMicroLamports": 0,
            "prioritizationFeeLamports": "auto",
            "asLegacyTransaction": false,
            "useTokenLedger": false,
            "dynamicComputeUnitLimit": true,
            "skipUserAccountsRpcCalls": false,
            "dynamicSlippage": {
                "minBps": 0,
                "maxBps": 0
            },
            "quoteResponse": quote,
        }
      };

    const swapInstructions = await this.jupiterQuoteApi.swapInstructionsPost(swapInstructionsRequest);
    return swapInstructions;
  }

  /**
   * Builds a complete swap transaction. Can optionally include a fee transfer instruction.
   * @param swapInstructions - Swap instructions from Jupiter
   * @param feeTransferInstruction - Optional fee transfer instruction
   * @returns Built transaction ready for signing
   * @throws Error if swap instructions are missing
   */
  async buildCompleteSwap(swapInstructions: SwapInstructionsResponse | null, feeTransferInstruction: TransactionInstruction | null) {
    // !! TODO: add genesis hash checks et al. from buildWhirlpoolsSwapToSOL if we don't trust Jupiter API
    if (!swapInstructions) {
        throw new Error("Swap instructions not found");
    }

    const allInstructions = [
        ...(feeTransferInstruction ? [feeTransferInstruction] : []),
        ...(swapInstructions.setupInstructions ?? []),
        swapInstructions.swapInstruction
    ].filter((instruction): instruction is TransactionInstruction => instruction !== undefined);

    const transaction = new Transaction();
    if (allInstructions.length > 0) {
        transaction.add(...allInstructions);
    }
    transaction.feePayer = this.feePayerKeypair.publicKey;
    
    transaction.recentBlockhash = (await this.connection.getLatestBlockhash()).blockhash;

    return transaction;
  }

  /**
   * Signs a transaction with token fee handling. Validates the transaction before signing.
   * @param transaction - Transaction to sign
   * @param buyWithUSDCBool - Whether this is a USDC buy transaction
   * @param tokenMint - Mint address of the fee token
   * @param tokenDecimals - Decimals of the fee token
   * @returns Signature as a string
   * @throws Error if signing fails
   */
  async signTransactionWithTokenFee(transaction: Transaction, buyWithUSDCBool: boolean, tokenMint: PublicKey, tokenDecimals: number): Promise<string> {
    try {
      const { signature } = await signWithTokenFee(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        [
            core.TokenFee.fromSerializable({
                mint: tokenMint.toString(),
                account: this.tradeFeeRecipient.toString(),
                decimals: tokenDecimals,
                fee: buyWithUSDCBool ? this.buyFee : this.sellFee
            })
        ],
        this.cache,
        2000 // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error signing transaction with token fee:", e);
      throw new Error("Failed to sign transaction with token fee");
    }
  }

  async createAccountWithTokenFee(transaction: Transaction, tokenMint: PublicKey, tokenDecimals: number): Promise<string> {
    try {
      const { signature } = await createAccountIfTokenFeePaid(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        [
            core.TokenFee.fromSerializable({
                mint: tokenMint.toString(),
                account: this.tradeFeeRecipient.toString(),
                decimals: tokenDecimals,
                fee: 0
            })
        ],
        this.cache,
        2000 // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error creating account with token fee:", e);
      throw new Error("Failed to create account with token fee");
    }
  }

  async validateTransactionInstructions(transaction: Transaction): Promise<void> {
    try {
      await core.validateInstructions(transaction, this.feePayerKeypair);
    } catch (e) {
      console.error("Error validating transaction instructions:", e);
      throw new Error("Invalid transaction instructions");
    }
  }

  /**
   * Signs a transaction that does not include token fee handling
   * @param transaction - Transaction to sign
   * @returns Signature as a string
   * @throws Error if signing fails
   */
  // !! TODO: validate transaction before signing
  async signTransactionWithoutTokenFee(transaction: Transaction): Promise<string> {
    try {
      transaction.partialSign(this.feePayerKeypair);
      return bs58.encode(transaction.signature!);
    } catch (e) {
      console.error("Error signing transaction without token fee:", e);
      throw new Error("Failed to sign transaction without token fee");
    }
  }
} 