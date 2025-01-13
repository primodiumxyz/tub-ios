import { Connection, TransactionMessage, VersionedTransaction, Keypair, PublicKey } from "@solana/web3.js";
import { DefaultApi, Configuration } from "@jup-ag/api";
import { JupiterService } from "../src/services/JupiterService";
import { TransactionService } from "../src/services/TransactionService";
import { describe, it, expect, beforeAll } from "vitest";
import { AxiosError } from "axios";
import { env } from "@bin/tub-server";
import { MEMECOIN_MAINNET_PUBLIC_KEY, SOL_MAINNET_PUBLIC_KEY, USDC_MAINNET_PUBLIC_KEY } from "../src/constants/tokens";
import { ConfigService } from "@/services/ConfigService";

const VERBOSE = false;
const createTestKeypair = () => Keypair.generate();

describe("Jupiter Quote Integration Test", () => {
  let connection: Connection;
  let jupiterQuoteApi: DefaultApi;
  let jupiterService: JupiterService;
  let transactionService: TransactionService;
  let feePayerPublicKey: PublicKey;

  beforeAll(async () => {
    try {
      if (VERBOSE) console.log("Setting up test environment...");
      connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`);

      jupiterQuoteApi = new DefaultApi(
        new Configuration({
          basePath: env.JUPITER_URL,
        }),
      );

      const feePayerKeypair = createTestKeypair();
      feePayerPublicKey = feePayerKeypair.publicKey;

      await ConfigService.getInstance();

      jupiterService = new JupiterService(connection, jupiterQuoteApi);
      transactionService = new TransactionService(connection, feePayerKeypair);
      if (VERBOSE) console.log("Test environment setup complete");
    } catch (error) {
      console.error("Error in test setup:", error);
      if (error instanceof Error) {
        console.error("Error message:", error.message);
        console.error("Stack trace:", error.stack);
      }
      throw error;
    }
  });

  it("should get a valid quote for SOL to USDC", async () => {
    const quoteRequest = {
      inputMint: SOL_MAINNET_PUBLIC_KEY.toString(), // SOL
      outputMint: USDC_MAINNET_PUBLIC_KEY.toString(), // USDC
      amount: 100000000, // 0.1 SOL
      slippageBps: 50,
      onlyDirectRoutes: true,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    try {
      if (VERBOSE) {
        console.log("\nGetting quote for SOL -> USDC:");
        console.log("Input: 0.1 SOL");
        console.log("Request:", quoteRequest);
      }

      const quote = await jupiterService.getQuote(quoteRequest);
      console.log("📨 Received quote response: SOL -> USDC");

      if (VERBOSE) {
        console.log({
          inputMint: quote.inputMint,
          outputMint: quote.outputMint,
          inAmount: `${Number(quote.inAmount) / 1e9} SOL`,
          outAmount: `${Number(quote.outAmount) / 1e6} USDC`,
          price: `${Number(quote.outAmount) / 1e6 / (Number(quote.inAmount) / 1e9)} USDC/SOL`,
          priceImpactPct: quote.priceImpactPct,
        });

        console.log("\nRoute Plan:");
        quote.routePlan.forEach((step, index) => {
          console.log(`\nStep ${index + 1}:`);
          console.log({
            protocol: step.swapInfo.label,
            inputMint: step.swapInfo.inputMint,
            outputMint: step.swapInfo.outputMint,
            inAmount: step.swapInfo.inAmount,
            outAmount: step.swapInfo.outAmount,
            fee: step.swapInfo.feeAmount,
            percent: `${step.percent}%`,
          });
        });
      }

      expect(quote).toBeDefined();
      expect(quote.inputMint).toBe(quoteRequest.inputMint);
      expect(quote.outputMint).toBe(quoteRequest.outputMint);
      expect(quote.inAmount).toBe(quoteRequest.amount.toString());
      expect(Number(quote.outAmount)).toBeGreaterThan(0);
    } catch (error) {
      console.error("Error getting quote:", error);
      throw error;
    }
  }, 5000);

  it("should get a valid quote for USDC to SOL", async () => {
    const quoteRequest = {
      inputMint: USDC_MAINNET_PUBLIC_KEY.toString(), // USDC
      outputMint: SOL_MAINNET_PUBLIC_KEY.toString(), // SOL
      amount: 1000000, // 1 USDC
      slippageBps: 50,
      onlyDirectRoutes: true,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    if (VERBOSE) {
      console.log("\nGetting quote for USDC -> SOL:");
      console.log("Input: 1 USDC");
    }

    const quote = await jupiterService.getQuote(quoteRequest);
    console.log("📨 Received quote response: USDC -> SOL");

    if (VERBOSE) {
      console.log({
        inputMint: quote.inputMint,
        outputMint: quote.outputMint,
        inAmount: `${Number(quote.inAmount) / 1e6} USDC`,
        outAmount: `${Number(quote.outAmount) / 1e9} SOL`,
        price: `${Number(quote.inAmount) / 1e6 / (Number(quote.outAmount) / 1e9)} USDC/SOL`,
        priceImpactPct: quote.priceImpactPct,
      });

      console.log("\nRoute Plan:");
      quote.routePlan.forEach((step, index) => {
        console.log(`\nStep ${index + 1}:`);
        console.log({
          protocol: step.swapInfo.label,
          inputMint: step.swapInfo.inputMint,
          outputMint: step.swapInfo.outputMint,
          inAmount: step.swapInfo.inAmount,
          outAmount: step.swapInfo.outAmount,
          fee: step.swapInfo.feeAmount,
          percent: `${step.percent}%`,
        });
      });
    }

    expect(quote).toBeDefined();
    expect(quote.inputMint).toBe(quoteRequest.inputMint);
    expect(quote.outputMint).toBe(quoteRequest.outputMint);
    expect(quote.inAmount).toBe(quoteRequest.amount.toString());
    expect(Number(quote.outAmount)).toBeGreaterThan(0);
  }, 5000);

  it("should get swap instructions after quote", async () => {
    // generate a new keypair for the user
    const userPublicKey = createTestKeypair().publicKey;

    const quoteRequest = {
      inputMint: SOL_MAINNET_PUBLIC_KEY.toString(), // SOL
      outputMint: USDC_MAINNET_PUBLIC_KEY.toString(), // USDC
      amount: 100000000, // 0.1 SOL
      slippageBps: 50,
      onlyDirectRoutes: true,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    try {
      if (VERBOSE) {
        console.log("\nTesting complete swap instruction flow:");
        console.log("User Public Key:", userPublicKey.toBase58());
        console.log("Quote Request:", quoteRequest);
      }

      const swapInstructions = await jupiterService.getSwapInstructions(quoteRequest, userPublicKey);
      console.log("📨 Received swap instructions: SOL -> USDC");

      if (VERBOSE) {
        console.log("\nSwap Instructions Response:", {
          hasSetupInstructions: !!swapInstructions.instructions?.length,
          setupInstructionsCount: swapInstructions.instructions?.length || 0,
          hasSwapInstruction: !!swapInstructions.instructions?.length,
          cleanupInstructionCount: swapInstructions.instructions?.length ? 1 : 0,
        });
      }

      const message = await transactionService.buildTransactionMessage(
        swapInstructions.instructions,
        swapInstructions.addressLookupTableAccounts,
        swapInstructions.quote.contextSlot ?? 0,
      );
      const transaction = new VersionedTransaction(message);

      console.log("📝 Built transaction message");
      await new Promise((resolve) => setTimeout(resolve, 1000));

      const decompiledMessage = TransactionMessage.decompile(message, {
        addressLookupTableAccounts: swapInstructions.addressLookupTableAccounts,
      });

      // Assertions
      expect(swapInstructions).toBeDefined();
      expect(swapInstructions.instructions).toBeDefined();
      expect(transaction).toBeDefined();
      expect(decompiledMessage.payerKey.equals(feePayerPublicKey)).toBe(true);
      expect(decompiledMessage.instructions.length).toBeGreaterThan(0);
      expect(decompiledMessage.recentBlockhash).toBeDefined();
    } catch (error) {
      console.error("Error testing swap instructions:");
      if (error instanceof AxiosError) {
        console.error("Status:", error.response?.status);
        console.error("Status Text:", error.response?.statusText);
        console.error("Response Headers:", error.response?.headers);
        console.error("Response Data:", JSON.stringify(error.response?.data, null, 2));
      } else if (error instanceof Error) {
        console.error("Error message:", error.message);
        console.error("Stack trace:", error.stack);
      }
      throw error;
    }
  }, 5000);

  it("should get swap instructions for USDC to SOL", async () => {
    const userPublicKey = createTestKeypair().publicKey;

    const quoteRequest = {
      inputMint: USDC_MAINNET_PUBLIC_KEY.toString(), // USDC
      outputMint: SOL_MAINNET_PUBLIC_KEY.toString(), // SOL
      amount: 1000000, // 1 USDC
      slippageBps: 50,
      onlyDirectRoutes: true,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    try {
      if (VERBOSE) {
        console.log("\nTesting USDC->SOL swap instruction flow:");
        console.log("User Public Key:", userPublicKey.toBase58());
        console.log("Quote Request:", quoteRequest);
      }

      const swapInstructions = await jupiterService.getSwapInstructions(quoteRequest, userPublicKey);
      console.log("📨 Received swap instructions: USDC -> SOL");

      const message = await transactionService.buildTransactionMessage(
        swapInstructions.instructions,
        swapInstructions.addressLookupTableAccounts,
        swapInstructions.quote.contextSlot ?? 0,
      );
      const transaction = new VersionedTransaction(message);
      console.log("📝 Built transaction message");

      const decompiledMessage = TransactionMessage.decompile(message, {
        addressLookupTableAccounts: swapInstructions.addressLookupTableAccounts,
      });

      if (VERBOSE) {
        console.log("\nBuilt Transaction:", {
          feePayer: decompiledMessage.payerKey.toBase58(),
          instructionsCount: decompiledMessage.instructions.length,
          recentBlockhash: decompiledMessage.recentBlockhash,
        });
      }

      // Assertions
      expect(swapInstructions).toBeDefined();
      expect(swapInstructions.instructions).toBeDefined();
      expect(transaction).toBeDefined();
      expect(decompiledMessage.payerKey.equals(feePayerPublicKey)).toBe(true);
      expect(decompiledMessage.instructions.length).toBeGreaterThan(0);
      expect(decompiledMessage.recentBlockhash).toBeDefined();
    } catch (error) {
      console.error("Error testing USDC->SOL swap instructions:");
      if (error instanceof AxiosError) {
        console.error("Status:", error.response?.status);
        console.error("Status Text:", error.response?.statusText);
        console.error("Response Headers:", error.response?.headers);
        console.error("Response Data:", JSON.stringify(error.response?.data, null, 2));
      } else if (error instanceof Error) {
        console.error("Error message:", error.message);
        console.error("Stack trace:", error.stack);
      }
      throw error;
    }
  }, 5000);

  it("should get instructions for USDC to MEMECOIN", async () => {
    const userPublicKey = createTestKeypair().publicKey;

    const quoteRequest = {
      inputMint: USDC_MAINNET_PUBLIC_KEY.toString(), // USDC
      outputMint: MEMECOIN_MAINNET_PUBLIC_KEY.toString(), // MEMECOIN
      amount: 1000000, // 1 USDC
      slippageBps: 50,
      onlyDirectRoutes: false,
      restrictIntermediateTokens: true,
      maxAccounts: 50,
      asLegacyTransaction: false,
    };

    const swapInstructions = await jupiterService.getSwapInstructions(quoteRequest, userPublicKey);
    console.log("📨 Received swap instructions: USDC -> MEMECOIN");
    if (VERBOSE) console.info("Instructions count:", swapInstructions.instructions?.length);
  });
});
