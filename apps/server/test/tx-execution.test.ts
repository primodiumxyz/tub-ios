import { Connection, Keypair } from "@solana/web3.js";
import { DefaultApi, Configuration } from "@jup-ag/api";
import { JupiterService } from "../src/services/JupiterService";
import { describe, it, beforeAll } from "vitest";
import { env } from "@bin/tub-server";

const createTestKeypair = () => Keypair.generate();

describe.skip("Tx Execution Test", () => {
  let connection: Connection;
  let jupiterQuoteApi: DefaultApi;
  let jupiterService: JupiterService;

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

      jupiterService = new JupiterService(connection, jupiterQuoteApi);
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
});
