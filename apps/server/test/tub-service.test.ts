import { describe, it, expect, beforeAll } from "vitest";
import { TubService } from "../src/services/TubService";
import { JupiterService } from "../src/services/JupiterService";
import { Connection, Keypair, VersionedTransaction, VersionedMessage } from "@solana/web3.js";
import { createJupiterApiClient } from "@jup-ag/api";
import { MockPrivyClient } from "./helpers/MockPrivyClient";
import { Codex } from "@codex-data/sdk";
import { createClient as createGqlClient } from "@tub/gql";
import bs58 from "bs58";
import { getAssociatedTokenAddress } from "@solana/spl-token";
import { USDC_MAINNET_PUBLIC_KEY, SOL_MAINNET_PUBLIC_KEY } from "@/constants/tokens";
import { env } from "@bin/tub-server";

// Skip entire suite in CI, because it would perform a live transaction each deployment
(env.CI ? describe.skip : describe)("TubService Integration Test", () => {
  let tubService: TubService;
  let userKeypair: Keypair;
  let mockJwtToken: string;
  let connection: Connection;

  beforeAll(async () => {
    try {
      // Setup connection to Solana mainnet
      connection = new Connection(env.QUICKNODE_MAINNET_URL ?? "https://api.mainnet-beta.solana.com");

      // Setup Jupiter API client
      const jupiterQuoteApi = createJupiterApiClient({
        basePath: env.JUPITER_URL,
      });

      // Create test fee payer keypair
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY!));

      // Create test user keypair from environment
      userKeypair = Keypair.fromSecretKey(bs58.decode(env.TEST_USER_PRIVATE_KEY!));
      console.log("User keypair:", userKeypair.publicKey.toBase58());
      mockJwtToken = "test_jwt_token";

      // Initialize services
      const jupiterService = new JupiterService(connection, jupiterQuoteApi);

      const gqlClient = (
        await createGqlClient({
          url: "http://localhost:8080/v1/graphql",
          hasuraAdminSecret: "password",
        })
      ).db;

      const codexSdk = new Codex(env.CODEX_API_KEY!);

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

      // Get fee payer token accounts
      const feePayerUsdcAta = await getAssociatedTokenAddress(USDC_MAINNET_PUBLIC_KEY, feePayerKeypair.publicKey);
      const feePayerSolAta = await getAssociatedTokenAddress(SOL_MAINNET_PUBLIC_KEY, feePayerKeypair.publicKey);

      // Get user token accounts
      const userUsdcAta = await getAssociatedTokenAddress(USDC_MAINNET_PUBLIC_KEY, userKeypair.publicKey);
      const userSolAta = await getAssociatedTokenAddress(SOL_MAINNET_PUBLIC_KEY, userKeypair.publicKey);

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

  describe.skip("swap execution", () => {
    it("should complete a USDC to SOL swap", async () => {
      try {
        console.log("\nStarting USDC to SOL swap flow test");
        console.log("User public key:", userKeypair.publicKey.toBase58());

        // Get the constructed swap transaction
        console.log("\nGetting 1 USDC to SOL swap transaction...");

        const swapResponse = await tubService.fetchSwap(mockJwtToken, {
          buyTokenId: SOL_MAINNET_PUBLIC_KEY.toString(),
          sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
          sellQuantity: 1e6 / 1000, // 0.001 USDC
        });

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
    }, 11000);

    it("should complete a USDC to GRIFT swap", async () => {
      const GRIFT_MINT = "DcRHumYETnVKowMmDSXQ5RcGrFZFAnaqrQ1AZCHXpump";
      // Get swap instructions
      const swapResponse = await tubService.fetchSwap(mockJwtToken, {
        buyTokenId: GRIFT_MINT,
        sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
        sellQuantity: 1e6 / 1000, // 0.001 USDC
      });

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
    }, 11000);
  });
});
