import { Connection, Keypair, PublicKey, Transaction, TransactionInstruction } from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@primodiumxyz/octane-core";
import { QuoteGetRequest, QuoteResponse, SwapInstructionsPostRequest, SwapInstructionsResponse } from "@jup-ag/api";
import { Wallet } from "@coral-xyz/anchor";
import bs58 from "bs58";
import type { Cache } from "cache-manager";
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
    private cache: Cache,
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
        amount: params.amount,
      });

      const quote = await this.jupiterQuoteApi.quoteGet(params);

      if (!quote) {
        throw new Error("unable to quote");
      }

      console.log(`[getQuote] Successfully received quote`);
      return quote;
    } catch (error) {
      console.error("[getQuote] Error getting quote:", error);
      throw new Error(`Failed to get quote: ${error instanceof Error ? error.message : "Unknown error"}`);
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

      const swapInstructionsRequest: SwapInstructionsPostRequest = {
        swapRequest: {
          quoteResponse: quote,
          userPublicKey: userPublicKey.toBase58(), // Make sure we're using toBase58()
          asLegacyTransaction: true,
          useSharedAccounts: false,
          wrapAndUnwrapSol: true,
          prioritizationFeeLamports: { autoMultiplier: 3 },
        },
      };

      try {
        const swapInstructions = await this.jupiterQuoteApi.swapInstructionsPost(swapInstructionsRequest);
        console.log("[getQuoteAndSwapInstructions] Received response:", {
          hasSetupInstructions: !!swapInstructions.setupInstructions?.length,
          hasSwapInstruction: !!swapInstructions.swapInstruction,
          hasCleanupInstruction: !!swapInstructions.cleanupInstruction,
        });
        return swapInstructions;
      } catch (error) {
        // Log the full error details
        if (error instanceof Error) {
          console.error("[getQuoteAndSwapInstructions] Detailed error:", {
            name: error.name,
            message: error.message,
            stack: error.stack,
          });
        }
        throw error;
      }
    } catch (error) {
      console.error("Error getting swap instructions:", error);
      throw new Error(`Failed to get swap instructions: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  /**
   * Builds a complete swap transaction. Can optionally include a fee transfer instruction.
   * @param swapInstructions - Swap instructions from Jupiter
   * @param feeTransferInstruction - Optional fee transfer instruction
   * @returns Built transaction ready for signing
   * @throws Error if swap instructions are missing
   */
  async buildCompleteSwap(
    swapInstructions: SwapInstructionsResponse | null,
    feeTransferInstruction: TransactionInstruction | null,
  ) {
    // !! TODO: add genesis hash checks et al. from buildWhirlpoolsSwapToSOL if we don't trust Jupiter API
    if (!swapInstructions) {
      throw new Error("Swap instructions not found");
    }

    console.log("[buildCompleteSwap] Building transaction with:", {
      hasSetupInstructions: !!swapInstructions.setupInstructions?.length,
      setupInstructionsCount: swapInstructions.setupInstructions?.length || 0,
      hasSwapInstruction: !!swapInstructions.swapInstruction,
      hasCleanupInstruction: !!swapInstructions.cleanupInstruction,
      hasFeeTransfer: !!feeTransferInstruction,
    });

    // Get blockhash first to ensure it's available
    const { blockhash } = await this.connection.getLatestBlockhash();

    // Create new transaction
    const transaction = new Transaction();
    transaction.feePayer = this.feePayerKeypair.publicKey;
    transaction.recentBlockhash = blockhash;

    // Add fee transfer first (if any)
    if (feeTransferInstruction) {
      transaction.add(feeTransferInstruction);
    }

    // Add Jupiter's instructions in their original order
    const jupiterInstructions = [
      ...(swapInstructions.setupInstructions || []),
      swapInstructions.swapInstruction,
      swapInstructions.cleanupInstruction,
    ].filter((ix) => ix !== null && ix !== undefined);

    // Add all Jupiter instructions preserving their exact data
    jupiterInstructions.forEach((instruction) => {
      // If this is an ATA creation instruction, modify it to use fee payer
      if (instruction.programId === "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL") {
        // Modify the account metas to make fee payer pay for rent
        const keys = instruction.accounts.map((acc) => ({
          pubkey: new PublicKey(acc.pubkey),
          isSigner: acc.isSigner,
          isWritable: acc.isWritable,
        }));

        // Make fee payer the rent payer
        keys[0] = {
          pubkey: this.feePayerKeypair.publicKey,
          isSigner: true,
          isWritable: true,
        };

        transaction.add(
          new TransactionInstruction({
            programId: new PublicKey(instruction.programId),
            keys,
            data: Buffer.from(instruction.data, "base64"),
          }),
        );
      } else if (instruction.programId === "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA") {
        // Try to decode the instruction data
        let instructionData: Buffer;
        try {
          instructionData = Buffer.from(instruction.data, "base64");
        } catch {
          instructionData = Buffer.from(instruction.data, "hex");
        }

        // Check if this is a CloseAccount instruction (opcode 9). If so, receive the residual funds as the FeePayer
        if (instructionData.length === 1 && instructionData[0] === 9) {
          // Modify the account metas to make fee payer receive the rent
          const keys = instruction.accounts.map((acc) => ({
            pubkey: new PublicKey(acc.pubkey),
            isSigner: acc.isSigner,
            isWritable: acc.isWritable,
          }));

          // Make fee payer the destination for rent refund
          keys[1] = {
            pubkey: this.feePayerKeypair.publicKey,
            isSigner: false,
            isWritable: true,
          };

          transaction.add(
            new TransactionInstruction({
              programId: new PublicKey(instruction.programId),
              keys,
              data: instructionData,
            }),
          );
        } else {
          // Handle instruction data based on its type
          let data: Buffer;
          if (typeof instruction.data === "string") {
            // Try base64 first, then hex
            try {
              data = Buffer.from(instruction.data, "base64");
            } catch {
              data = Buffer.from(instruction.data, "hex");
            }
          } else if (Array.isArray(instruction.data)) {
            data = Buffer.from(instruction.data);
          } else {
            // If it's not a string or array, assume it's already a Buffer
            data = instruction.data;
          }

          transaction.add(
            new TransactionInstruction({
              programId: new PublicKey(instruction.programId),
              keys: instruction.accounts.map((acc) => ({
                pubkey: new PublicKey(acc.pubkey),
                isSigner: acc.isSigner,
                isWritable: acc.isWritable,
              })),
              data,
            }),
          );
        }
      } else {
        // Handle instruction data based on its type
        let data: Buffer;
        if (typeof instruction.data === "string") {
          // Try base64 first, then hex
          try {
            data = Buffer.from(instruction.data, "base64");
          } catch {
            data = Buffer.from(instruction.data, "hex");
          }
        } else if (Array.isArray(instruction.data)) {
          data = Buffer.from(instruction.data);
        } else {
          // If it's not a string or array, assume it's already a Buffer
          data = instruction.data;
        }

        transaction.add(
          new TransactionInstruction({
            programId: new PublicKey(instruction.programId),
            keys: instruction.accounts.map((acc) => ({
              pubkey: new PublicKey(acc.pubkey),
              isSigner: acc.isSigner,
              isWritable: acc.isWritable,
            })),
            data,
          }),
        );
      }
    });

    // Verify transaction can be serialized
    try {
      transaction.serialize({ requireAllSignatures: false });
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
  async signTransactionWithTokenFee(
    transaction: Transaction,
    buyWithUSDCBool: boolean,
    tokenMint: PublicKey,
    tokenDecimals: number,
  ): Promise<string> {
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
            fee: buyWithUSDCBool ? this.buyFee : this.sellFee,
          }),
        ],
        this.cache,
        2000, // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error signing transaction with token fee:", e);
      throw new Error("Failed to sign transaction with token fee");
    }
  }

  async createAccountWithTokenFee(
    transaction: Transaction,
    tokenMint: PublicKey,
    tokenDecimals: number,
  ): Promise<string> {
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
            fee: 0,
          }),
        ],
        this.cache,
        2000, // sameSourceTimeout
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

  private convertToTransactionInstruction(instruction: {
    programId: string;
    data: string | number[] | Buffer;
    accounts: Array<{
      pubkey: string;
      isSigner: boolean;
      isWritable: boolean;
    }>;
  }): TransactionInstruction {
    // Handle instruction data properly
    let data: Buffer;
    if (typeof instruction.data === "string") {
      // If it's a hex string, remove '0x' prefix if present
      const hex = instruction.data.startsWith("0x") ? instruction.data.slice(2) : instruction.data;
      data = Buffer.from(hex, "hex");
    } else if (Array.isArray(instruction.data)) {
      // If it's a byte array
      data = Buffer.from(instruction.data);
    } else if (instruction.data instanceof Buffer) {
      // If it's already a Buffer
      data = instruction.data;
    } else {
      console.error("Invalid instruction data format:", instruction.data);
      throw new Error("Invalid instruction data format");
    }

    // Map accounts with proper key conversion
    const keys = instruction.accounts.map((account: { pubkey: string; isSigner: boolean; isWritable: boolean }) => ({
      pubkey: new PublicKey(account.pubkey),
      isSigner: account.isSigner,
      isWritable: account.isWritable,
    }));

    return new TransactionInstruction({
      programId: new PublicKey(instruction.programId),
      keys,
      data,
    });
  }
}
