import {
  Connection,
  Keypair,
  PublicKey,
  Transaction,
  TransactionInstruction,
  AddressLookupTableAccount,
  TransactionMessage,
  VersionedTransaction,
} from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@primodiumxyz/octane-core";
import { Instruction, QuoteGetRequest, QuoteResponse, SwapInstructionsPostRequest } from "@jup-ag/api";
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

  /**
   * Gets swap instructions for a quoted trade
   * @param quoteAndSwapParams - Parameters for quote and swap
   * @param userPublicKey - User's public key
   * @returns Swap instructions from Jupiter
   */
  async getSwapInstructions(
    quoteAndSwapParams: QuoteGetRequest,
    userPublicKey: PublicKey,
  ): Promise<{
    instructions: TransactionInstruction[];
    addressLookupTableAccounts: AddressLookupTableAccount[];
  }> {
    try {
      const quote = await this.getQuote(quoteAndSwapParams);

      const swapInstructionsRequest: SwapInstructionsPostRequest = {
        swapRequest: {
          quoteResponse: quote,
          userPublicKey: userPublicKey.toBase58(),
          asLegacyTransaction: quoteAndSwapParams.asLegacyTransaction,
          wrapAndUnwrapSol: true,
          prioritizationFeeLamports: { autoMultiplier: 3 },
        },
      };

      const swapInstructions = await this.jupiterQuoteApi.swapInstructionsPost(swapInstructionsRequest);
      const {
        setupInstructions,
        swapInstruction: swapInstructionPayload,
        cleanupInstruction,
        addressLookupTableAddresses,
      } = swapInstructions;

      console.log("getSwapInstructions", addressLookupTableAddresses);
      const addressLookupTableAccounts = await this.getAddressLookupTableAccounts(addressLookupTableAddresses);

      const finalInstructions = [
        ...setupInstructions.map(this.deserializeInstruction),
        this.deserializeInstruction(swapInstructionPayload),
      ];
      if (cleanupInstruction) {
        finalInstructions.push(this.deserializeInstruction(cleanupInstruction));
      }

      return {
        instructions: finalInstructions,
        addressLookupTableAccounts,
      };
    } catch (error) {
      console.error("Error getting swap instructions:", error);
      throw new Error(`Failed to get swap instructions: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  // Function to get swap instructions
  deserializeInstruction = (instruction: Instruction) =>
    new TransactionInstruction({
      programId: new PublicKey(instruction.programId),
      keys: instruction.accounts.map((key) => ({
        pubkey: new PublicKey(key.pubkey),
        isSigner: key.isSigner,
        isWritable: key.isWritable,
      })),
      data: Buffer.from(instruction.data, "base64"),
    });

  getAddressLookupTableAccounts = async (keys: string[]): Promise<AddressLookupTableAccount[]> => {
    const addressLookupTableAccountInfos = await this.connection.getMultipleAccountsInfo(
      keys.map((key) => new PublicKey(key)),
    );

    return addressLookupTableAccountInfos.reduce((acc, accountInfo, index) => {
      if (accountInfo) {
        acc.push(
          new AddressLookupTableAccount({
            key: new PublicKey(keys[index]!),
            state: AddressLookupTableAccount.deserialize(accountInfo.data),
          }),
        );
      }
      return acc;
    }, new Array<AddressLookupTableAccount>());
  };
  /**
   * Builds a complete swap transaction. Can optionally include a fee transfer instruction.
   * @param swapInstructions - Swap instructions from Jupiter
   * @param feeTransferInstruction - Optional fee transfer instruction
   * @returns Built transaction ready for signing
   * @throws Error if swap instructions are missing
   */
  async buildSwapMessage(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
  ) {
    console.log("buildSwapMessage", instructions.length, addressLookupTableAccounts.length);
    // Get blockhash first to ensure it's available
    const { blockhash } = await this.connection.getLatestBlockhash();

    // Create a v0 message with necessary instructions, depending on the mint
    console.log("building Swap Message", instructions.length, addressLookupTableAccounts.length);
    const messageV0 = new TransactionMessage({
      payerKey: this.feePayerKeypair.publicKey,
      recentBlockhash: blockhash,
      instructions,
      // Compile to a versioned message, and add lookup table accounts
    }).compileToV0Message(addressLookupTableAccounts);

    // Verify transaction can be serialized
    try {
      messageV0.serialize();
    } catch (error) {
      console.error("[buildCompleteSwap] Failed to serialize transaction:", error);
      throw error;
    }

    return messageV0;
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
  async signTransactionWithoutCheckingTokenFee(transaction: VersionedTransaction): Promise<string> {
    try {
      transaction.sign([this.feePayerKeypair]);
      const signature = transaction.signatures[0];
      if (!signature) {
        throw new Error("No signature found");
      }
      return bs58.encode(signature);
    } catch (e) {
      console.error("Error signing transaction without token fee:", e);
      throw new Error("Failed to sign transaction without token fee");
    }
  }
}
