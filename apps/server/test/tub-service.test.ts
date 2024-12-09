import { describe, it, expect, beforeAll } from "vitest";
import { TubService } from "../src/TubService";
import { JupiterService } from "../src/JupiterService";
import { Connection, Keypair, PublicKey, VersionedTransaction, VersionedMessage } from "@solana/web3.js";
import { createJupiterApiClient } from "@jup-ag/api";
import { MockPrivyClient } from "./helpers/MockPrivyClient";
import { Codex } from "@codex-data/sdk";
import { createClient as createGqlClient } from "@tub/gql";
import bs58 from "bs58";
import { getAssociatedTokenAddress } from "@solana/spl-token";

// Skip entire suite in CI, because it would perform a live transaction each deployment
(process.env.CI ? describe.skip : describe)("TubService Integration Test", () => {
  let tubService: TubService;
  let userKeypair: Keypair;
  let mockJwtToken: string;
  let connection: Connection;

  beforeAll(async () => {
    try {
      if (!process.env.TEST_USER_PRIVATE_KEY) {
        throw new Error("TEST_USER_PRIVATE_KEY not found in environment");
      }

      // Setup connection to Solana mainnet
      connection = new Connection(process.env.QUICKNODE_MAINNET_URL ?? "https://api.mainnet-beta.solana.com");

      // Setup Jupiter API client
      const jupiterQuoteApi = createJupiterApiClient({
        basePath: process.env.JUPITER_URL,
      });

      // Create cache for JupiterService
      const cache = await (
        await import("cache-manager")
      ).caching({
        store: "memory",
        max: 100,
        ttl: 10 * 1000, // 10 seconds
      });

      // Create test fee payer keypair
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(process.env.FEE_PAYER_PRIVATE_KEY!));

      // Create test user keypair from environment
      userKeypair = Keypair.fromSecretKey(bs58.decode(process.env.TEST_USER_PRIVATE_KEY));
      mockJwtToken = "test_jwt_token";

      // Initialize services
      const jupiterService = new JupiterService(
        connection,
        jupiterQuoteApi,
        feePayerKeypair.publicKey,
        new PublicKey(process.env.OCTANE_TRADE_FEE_RECIPIENT!),
        Number(process.env.OCTANE_BUY_FEE),
        0, // sell fee
        15, // min trade size
        cache,
      );

      const gqlClient = (
        await createGqlClient({
          url: "http://localhost:8080/v1/graphql",
          hasuraAdminSecret: "password",
        })
      ).db;

      const codexSdk = new Codex(process.env.CODEX_API_KEY!);

      // Create mock Privy client with our test wallet
      const mockPrivyClient = new MockPrivyClient(userKeypair.publicKey.toString());

      tubService = new TubService(
        gqlClient,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        mockPrivyClient as any,
        codexSdk,
        jupiterService,
      );

      console.log("\nTest setup complete with user public key:", userKeypair.publicKey.toBase58());

      // Log all relevant token accounts
      const USDC_MINT = new PublicKey("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");
      const SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

      // Get fee payer token accounts
      const feePayerUsdcAta = await getAssociatedTokenAddress(USDC_MINT, feePayerKeypair.publicKey);
      const feePayerSolAta = await getAssociatedTokenAddress(SOL_MINT, feePayerKeypair.publicKey);

      // Get user token accounts
      const userUsdcAta = await getAssociatedTokenAddress(USDC_MINT, userKeypair.publicKey);
      const userSolAta = await getAssociatedTokenAddress(SOL_MINT, userKeypair.publicKey);

      console.log("\nToken Accounts:");
      console.log("Fee Payer:", feePayerKeypair.publicKey.toBase58());
      console.log("Fee Payer USDC ATA:", feePayerUsdcAta.toBase58());
      console.log("Fee Payer SOL ATA:", feePayerSolAta.toBase58());
      console.log("\nUser:", userKeypair.publicKey.toBase58());
      console.log("User USDC ATA:", userUsdcAta.toBase58());
      console.log("User SOL ATA:", userSolAta.toBase58());

      // Check USDC balance
      try {
        const balance = await connection.getTokenAccountBalance(userUsdcAta);
        if (!balance.value.uiAmount || balance.value.uiAmount < 1) {
          throw new Error(`Test account needs at least 1 USDC. Current balance: ${balance.value.uiAmount ?? 0} USDC`);
        }
        console.log(`USDC balance: ${balance.value.uiAmount} USDC`);
      } catch {
        throw new Error("Test account needs a USDC token account with at least 1 USDC");
      }
    } catch (error) {
      console.error("Error in test setup:", error);
      throw error;
    }
  });

  describe("should complete a full USDC to SOL swap flow", () => {
    it("should complete a full USDC to SOL swap flow", async () => {
      try {
        console.log("\nStarting USDC to SOL swap flow test");
        console.log("User public key:", userKeypair.publicKey.toBase58());

        // Get the constructed swap transaction
        console.log("\nGetting 1 USDC to SOL swap transaction...");
        const swapResponse = await tubService.get1USDCToSOLTransaction(mockJwtToken);

        // --- Begin Simulating Mock Privy Interaction ---

        // Decode transaction
        const handoff = Buffer.from(swapResponse.transactionMessageBase64, "base64");
        const message = VersionedMessage.deserialize(handoff);
        const transaction = new VersionedTransaction(message);

        // User signs
        transaction.sign([userKeypair]);
        const userSignature = transaction.signatures![1];
        if (!userSignature) {
          throw new Error("Failed to get signature from transaction");
        }

        // Convert raw signature to base64
        const base64Signature = Buffer.from(userSignature).toString("base64");

        // --- End Simulating Mock Privy Interaction ---

        const result = await tubService.signAndSendTransaction(
          mockJwtToken,
          base64Signature,
          swapResponse.transactionMessageBase64, // Send original unsigned transaction
        );

        console.log("Transaction result:", result);

        expect(result).toBeDefined();
        expect(result.signature).toBeDefined();
      } catch (error) {
        console.error("Error in swap flow test:", error);
        throw error;
      }
    }, 30000);
  });
});
