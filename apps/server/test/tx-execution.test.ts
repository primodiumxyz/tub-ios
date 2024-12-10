import { Connection, PublicKey, Keypair } from "@solana/web3.js";
import { DefaultApi, Configuration } from "@jup-ag/api";
import { JupiterService } from "../src/services/JupiterService";
import { TransactionService } from "../src/services/TransactionService";
import { Cache } from "cache-manager";
import { describe, it, beforeAll } from "vitest";
import { env } from "@bin/tub-server";

const createTestKeypair = () => Keypair.generate();

describe.skip("Tx Execution Test", () => {
  let connection: Connection;
  let jupiterQuoteApi: DefaultApi;
  let jupiterService: JupiterService;
  let transactionService: TransactionService;
  let cache: Cache;

  beforeAll(async () => {
    try {
      // Setup connection to Solana mainnet
      connection = new Connection(env.QUICKNODE_MAINNET_URL ?? "https://api.mainnet-beta.solana.com");

      // Setup Jupiter API client
      jupiterQuoteApi = new DefaultApi(
        new Configuration({
          basePath: env.JUPITER_URL,
        }),
      );

      const feePayerKeypair = createTestKeypair();
      const feePayerPublicKey = feePayerKeypair.publicKey;

      jupiterService = new JupiterService(
        connection,
        jupiterQuoteApi,
        feePayerPublicKey,
        new PublicKey("11111111111111111111111111111111"),
        100,
        0,
        15,
        cache,
      );
      transactionService = new TransactionService(connection, feePayerKeypair, feePayerPublicKey);
    } catch (error) {
      console.error("Error in test setup:", error);
      if (error instanceof Error) {
        console.error("Error message:", error.message);
        console.error("Stack trace:", error.stack);
      }
      throw error;
    }
  });

  const quoteRequest = {
    inputMint: "DcRHumYETnVKowMmDSXQ5RcGrFZFAnaqrQ1AZCHXpump", // $GRIFT
    outputMint: "So11111111111111111111111111111111111111112", // SOL
    amount: 1000000, // 1 USDC
    slippageBps: 50,
    onlyDirectRoutes: false,
    restrictIntermediateTokens: true,
    maxAccounts: 50,
    asLegacyTransaction: false,
  };
  const testKeypair = createTestKeypair();

  it("should get instructions for USDC to GRIFT", async () => {
    const swapInstructions = await jupiterService.getSwapInstructions(quoteRequest, testKeypair.publicKey);
    console.info("content:", swapInstructions.instructions?.length);
  });

  it("should execute the tx", async () => {
    // Get swap instructions
    const swapInstructions = await jupiterService.getSwapInstructions(quoteRequest, testKeypair.publicKey);

    // Build transaction message
    const message = await transactionService.buildTransactionMessage(
      swapInstructions.instructions,
      swapInstructions.addressLookupTableAccounts,
    );

    // Register transaction
    const base64Message = transactionService.registerTransaction(message);

    // Sign and send transaction
    const userSignature = "user_signature_base64"; // Replace with actual user signature
    const tx = await transactionService.signAndSendTransaction(testKeypair.publicKey, userSignature, base64Message);

    console.info("tx:", tx);
  });
});
