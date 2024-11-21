import { Connection, Keypair, PublicKey, Transaction, TransactionInstruction } from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@primodiumxyz/octane-core";
import { QuoteGetRequest, QuoteResponse, SwapInstructionsPostRequest, SwapInstructionsResponse } from '@jup-ag/api';
import { Wallet } from "@coral-xyz/anchor";
import bs58 from "bs58";
import type { Cache } from 'cache-manager';
import { DefaultApi } from "@jup-ag/api";

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
    try {
      console.log(`[getQuote] Requesting quote with params:`, {
        inputMint: params.inputMint,
        outputMint: params.outputMint,
        amount: params.amount
      });

      const quote = await this.jupiterQuoteApi.quoteGet(params);
      
      if (!quote) {
        throw new Error("unable to quote");
      }

      console.log(`[getQuote] Successfully received quote`);
      return quote;

    } catch (error) {
      console.error("[getQuote] Error getting quote:", error);
      throw new Error(`Failed to get quote: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
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
    try {
      const quote = await this.getQuote(quoteAndSwapParams);
      console.dir(quote, { depth: null });

      // Log the API instance details
      console.log("[getQuoteAndSwapInstructions] API Configuration:", {
        basePath: (this.jupiterQuoteApi as any).configuration?.basePath,
        availableMethods: Object.keys(this.jupiterQuoteApi)
      });

      console.log("[getQuoteAndSwapInstructions] User public key:", userPublicKey.toBase58());
      console.log("[getQuoteAndSwapInstructions] User public key:", userPublicKey);

      const swapInstructionsRequest: SwapInstructionsPostRequest = {
        swapRequest: {
          quoteResponse: quote,
          userPublicKey: userPublicKey.toBase58(), // Make sure we're using toBase58()
        }
      };

      console.log("[getQuoteAndSwapInstructions] Sending request:", {
        url: `${(this.jupiterQuoteApi as any).configuration?.basePath}/swap-instructions`,
        request: JSON.stringify(swapInstructionsRequest, null, 2)
      });

      try {
        const swapInstructions = await this.jupiterQuoteApi.swapInstructionsPost(swapInstructionsRequest);
        console.log("[getQuoteAndSwapInstructions] Received response:", {
          hasSetupInstructions: !!swapInstructions.setupInstructions?.length,
          hasSwapInstruction: !!swapInstructions.swapInstruction,
          hasCleanupInstruction: !!swapInstructions.cleanupInstruction
        });
        return swapInstructions;
      } catch (error) {
        // Log the full error details
        if (error instanceof Error) {
          console.error("[getQuoteAndSwapInstructions] Detailed error:", {
            name: error.name,
            message: error.message,
            stack: error.stack,
            response: (error as any).response?.data,
            status: (error as any).response?.status,
            headers: (error as any).response?.headers
          });
        }
        throw error;
      }
    } catch (error) {
      console.error("Error getting swap instructions:", error);
      throw new Error(`Failed to get swap instructions: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
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

    console.log("[buildCompleteSwap] Building transaction with:", {
      hasSetupInstructions: !!swapInstructions.setupInstructions?.length,
      setupInstructionsCount: swapInstructions.setupInstructions?.length || 0,
      hasSwapInstruction: !!swapInstructions.swapInstruction,
      hasCleanupInstruction: !!swapInstructions.cleanupInstruction,
      hasFeeTransfer: !!feeTransferInstruction
    });

    // Get blockhash first to ensure it's available
    const { blockhash, lastValidBlockHeight } = await this.connection.getLatestBlockhash();

    // Create transaction with all required fields
    const transaction = new Transaction();
    transaction.feePayer = this.feePayerKeypair.publicKey;
    transaction.recentBlockhash = blockhash;
    transaction.lastValidBlockHeight = lastValidBlockHeight;

    // Add instructions one by one to ensure they're properly added
    if (feeTransferInstruction) {
      transaction.add(feeTransferInstruction);
    }

    if (swapInstructions.setupInstructions?.length) {
      swapInstructions.setupInstructions.forEach(instruction => {
        if (instruction) {
          transaction.add(this.convertToTransactionInstruction(instruction));
        }
      });
    }

    if (swapInstructions.swapInstruction) {
      transaction.add(this.convertToTransactionInstruction(swapInstructions.swapInstruction));
    }

    if (swapInstructions.cleanupInstruction) {
      transaction.add(this.convertToTransactionInstruction(swapInstructions.cleanupInstruction));
    }

    console.log("[buildCompleteSwap] Created instruction array:", {
      instructionCount: transaction.instructions.length,
      hasFeeTransfer: !!feeTransferInstruction,
      hasSwapInstruction: !!swapInstructions.swapInstruction,
      hasCleanupInstruction: !!swapInstructions.cleanupInstruction,
      instructions: transaction.instructions.map(i => ({
        programId: i?.programId?.toBase58() || 'unknown',
        keys: i?.keys?.length || 0,
        data: i?.data?.length || 0
      }))
    });

    // Verify transaction can be serialized
    try {
      transaction.serialize({ requireAllSignatures: false });
      console.log("[buildCompleteSwap] Successfully verified transaction serialization");
    } catch (error) {
      console.error("[buildCompleteSwap] Failed to serialize transaction:", error);
      throw error;
    }

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

  private convertToTransactionInstruction(instruction: any): TransactionInstruction {
    return new TransactionInstruction({
      programId: new PublicKey(instruction.programId),
      keys: instruction.accounts.map((account: { pubkey: string; isSigner: boolean; isWritable: boolean }) => ({
        pubkey: new PublicKey(account.pubkey),
        isSigner: account.isSigner,
        isWritable: account.isWritable
      })),
      data: Buffer.from(instruction.data)
    });
  }
} 