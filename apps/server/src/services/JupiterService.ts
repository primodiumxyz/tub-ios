import { Connection, PublicKey, TransactionInstruction, AddressLookupTableAccount } from "@solana/web3.js";
import { DefaultApi, QuoteGetRequest, SwapInstructionsPostRequest } from "@jup-ag/api";
import { EventEmitter } from "events";
import { SOL_USD_PRICE_UPDATE_INTERVAL } from "../constants/registry";

export type JupiterSettings = {
  connection: Connection;
  jupiterQuoteApi: DefaultApi;
};

interface JupiterInstruction {
  programId: string;
  accounts: Array<{
    pubkey: string;
    isSigner: boolean;
    isWritable: boolean;
  }>;
  data: string;
}

/**
 * Service for interacting with Jupiter API
 */
export class JupiterService {
  private solUsdPrice: number | undefined;
  private priceEmitter = new EventEmitter();

  /**
   * Creates a new instance of JupiterService
   * @param connection - Solana RPC connection
   * @param jupiterQuoteApi - Jupiter API client
   */
  constructor(
    private connection: Connection,
    private jupiterQuoteApi: DefaultApi,
  ) {
    // Update the SOL/USD price at every interval
    const interval = setInterval(() => {
      this.updateSolUsdPrice();
    }, SOL_USD_PRICE_UPDATE_INTERVAL);
    this.updateSolUsdPrice();

    interval.unref(); // allow Node.js to exit if only this interval is still running
  }

  getSettings(): JupiterSettings {
    return {
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

  private deserializeInstruction(instruction: JupiterInstruction): TransactionInstruction {
    return new TransactionInstruction({
      programId: new PublicKey(instruction.programId),
      keys: instruction.accounts.map((account) => ({
        pubkey: new PublicKey(account.pubkey),
        isSigner: account.isSigner,
        isWritable: account.isWritable,
      })),
      data: Buffer.from(instruction.data, "base64"),
    });
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
      if (!swapInstructions) {
        throw new Error("No swap instructions received");
      }

      const addressLookupTableAccounts = await Promise.all(
        (swapInstructions.addressLookupTableAddresses || []).map(async (address) => {
          const account = await this.connection.getAddressLookupTable(new PublicKey(address));
          if (!account?.value) {
            throw new Error(`Could not fetch address lookup table account ${address}`);
          }
          return account.value;
        }),
      );

      // Combine all instructions in the correct order
      const allInstructions: TransactionInstruction[] = [
        ...(swapInstructions.computeBudgetInstructions || []).map(this.deserializeInstruction),
        ...(swapInstructions.setupInstructions || []).map(this.deserializeInstruction),
        swapInstructions.swapInstruction ? this.deserializeInstruction(swapInstructions.swapInstruction) : [],
        ...(swapInstructions.cleanupInstruction
          ? [this.deserializeInstruction(swapInstructions.cleanupInstruction)]
          : []),
      ].flat();

      return {
        instructions: allInstructions,
        addressLookupTableAccounts,
      };
    } catch (error) {
      console.error("[getSwapInstructions] Error getting swap instructions:", error);
      throw new Error(`Failed to get swap instructions: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
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
      const res = await this.jupiterQuoteApi.quoteGet({
        inputMint: "So11111111111111111111111111111111111111112",
        outputMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        amount: 1 * 1e9, // convert to lamports
      });

      this.solUsdPrice = Number(res.outAmount) / 1e6; // convert to USD from USDC (6 decimals)
      this.priceEmitter.emit("price", this.solUsdPrice);

      console.log(`SOL/USD price updated: ${this.solUsdPrice?.toLocaleString("en-US", { maximumFractionDigits: 2 })}`);
    } catch (error) {
      console.error("Error updating SOL/USD price:", error);
    }
  }
}
