import { Connection, PublicKey, TransactionInstruction, AddressLookupTableAccount } from "@solana/web3.js";
import { DefaultApi, QuoteGetRequest, QuoteResponse, SwapInstructionsPostRequest } from "@jup-ag/api";
import { EventEmitter } from "events";
import { config } from "../utils/config";
import { SOL_MAINNET_PUBLIC_KEY, USDC_MAINNET_PUBLIC_KEY } from "../constants/tokens";

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
    this.initializePriceUpdates();
  }

  private initializePriceUpdates(): void {
    (async () => {
      const interval = setInterval(
        async () => {
          await this.updateSolUsdPrice();
        },
        (await config()).SOL_USD_PRICE_UPDATE_INTERVAL,
      );

      this.updateSolUsdPrice();
      interval.unref();
    })();
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
   * @param autoPriorityFeeMultiplier - Auto priority fee multiplier
   * @returns Swap instructions from Jupiter
   */
  async getSwapInstructions(
    quoteAndSwapParams: QuoteGetRequest,
    userPublicKey: PublicKey,
    autoPriorityFeeMultiplier: number,
  ): Promise<{
    instructions: TransactionInstruction[];
    addressLookupTableAccounts: AddressLookupTableAccount[];
    quote: QuoteResponse;
  }> {
    try {
      const minSlippage = (await config()).MIN_SLIPPAGE_BPS;

      const quote = await this.getQuote(quoteAndSwapParams);

      if (!quote) {
        throw new Error("No quote received");
      }

      let dynamicSlippage: undefined | { minBps: number; maxBps: number } = undefined;
      // override computedAutoSlippage if it is less than MIN_SLIPPAGE_BPS
      if (quote.computedAutoSlippage) {
        if (quote.computedAutoSlippage <= minSlippage) {
          dynamicSlippage = { minBps: minSlippage, maxBps: minSlippage };
        }
      }

      const swapInstructionsRequest: SwapInstructionsPostRequest = {
        swapRequest: {
          quoteResponse: quote,
          userPublicKey: userPublicKey.toBase58(),
          asLegacyTransaction: quoteAndSwapParams.asLegacyTransaction,
          wrapAndUnwrapSol: true,
          prioritizationFeeLamports: { autoMultiplier: autoPriorityFeeMultiplier },
          dynamicSlippage: dynamicSlippage,
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
        quote,
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
        inputMint: SOL_MAINNET_PUBLIC_KEY.toString(),
        outputMint: USDC_MAINNET_PUBLIC_KEY.toString(),
        amount: 1 * 1e9, // convert to lamports
      });

      this.solUsdPrice = Number(res.outAmount) / 1e6; // convert to USD from USDC (6 decimals)
      this.priceEmitter.emit("price", this.solUsdPrice);
    } catch (error) {
      console.error("Error updating SOL/USD price:", error);
    }
  }
}
