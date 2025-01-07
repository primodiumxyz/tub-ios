import { describe, it, expect, beforeAll } from "vitest";
import { TubService } from "../src/services/TubService";
import { JupiterService } from "../src/services/JupiterService";
import { Connection, Keypair, VersionedTransaction, VersionedMessage } from "@solana/web3.js";
import { createJupiterApiClient } from "@jup-ag/api";
import { MockPrivyClient } from "./helpers/MockPrivyClient";
import { createClient as createGqlClient } from "@tub/gql";
import bs58 from "bs58";
import { getAssociatedTokenAddress } from "@solana/spl-token";
import { env } from "../bin/tub-server";
import { PrebuildSwapResponse } from "../src/types";
import { USDC_MAINNET_PUBLIC_KEY, SOL_MAINNET_PUBLIC_KEY, MEMECOIN_MAINNET_PUBLIC_KEY } from "../src/constants/tokens";
import { ConfigService } from "../src/services/ConfigService";
// Skip entire suite in CI, because it would perform a live transaction each deployment
(env.CI ? describe.skip : describe)("TubService Integration Test", () => {
  let tubService: TubService;
  let userKeypair: Keypair;
  let mockJwtToken: string;
  let connection: Connection;

  beforeAll(async () => {
    try {
      // Setup connection to Solana mainnet
      connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`);
      await ConfigService.getInstance();

      // Setup Jupiter API client
      const jupiterQuoteApi = createJupiterApiClient({
        basePath: env.JUPITER_URL,
      });

      // Create test fee payer keypair
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));

      // Create test user keypair from environment
      userKeypair = Keypair.fromSecretKey(bs58.decode(env.TEST_USER_PRIVATE_KEY));
      console.log("User keypair:", userKeypair.publicKey.toBase58());
      mockJwtToken = "test_jwt_token";

      // Initialize services
      const jupiterService = new JupiterService(connection, jupiterQuoteApi);

      const gqlClient = (
        await createGqlClient({
          url: "http://localhost:8090/v1/graphql",
          hasuraAdminSecret: "password",
        })
      ).db;

      // Create mock Privy client with our test wallet
      const mockPrivyClient = new MockPrivyClient(userKeypair.publicKey.toString());

      tubService = await TubService.create(
        gqlClient,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        mockPrivyClient as any,
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
      const balance = await connection.getTokenAccountBalance(userUsdcAta, "processed");
      if (!balance.value.uiAmount) {
        console.warn("⚠️  Warning: Test account missing USDC token account. Some tests may fail.");
      }
      if (!!balance.value.uiAmount && balance.value.uiAmount < 1) {
        console.warn(
          `⚠️  Warning: Test account has low USDC balance: ${balance.value.uiAmount ?? 0} USDC. Some tests may fail.`,
        );
      }
    } catch (error) {
      console.error("Error in test setup:", error);
      throw error;
    }
  });

  describe("getBalance", () => {
    it("should get the user's balance", async () => {
      const balance = await tubService.getBalance(mockJwtToken);
      expect(balance).toBeDefined();
      expect(balance.balance).toBeGreaterThan(0);
    });

    it("should get the user's usdc balance", async () => {
      const balance = await tubService.getTokenBalance(mockJwtToken, USDC_MAINNET_PUBLIC_KEY.toString());
      expect(balance).toBeDefined();
      expect(balance.balance).toBeGreaterThan(0);
    });

    it("should get the user's token balances", async () => {
      const { tokenBalances } = await tubService.getAllTokenBalances(mockJwtToken);
      expect(tokenBalances).toBeDefined();
      expect(tokenBalances.length).toBeGreaterThan(0);
    });

    it("should get the user's usdc balance", async () => {
      const { tokenBalances } = await tubService.getAllTokenBalances(mockJwtToken);
      if (tokenBalances.length === 0) {
        console.log("No token balances found, skipping test");
        return;
      }

      const token = tokenBalances[0]?.mint;
      if (!token) {
        console.log("No token found, skipping test");
        return;
      }

      const balance = await tubService.getTokenBalance(mockJwtToken, token);
      expect(balance).toBeDefined();
      expect(balance.balance).toEqual(tokenBalances[0]?.balanceToken);
    });
  });

  describe("swap execution", () => {
    const executeTx = async (swapResponse: PrebuildSwapResponse) => {
      const handoff = Buffer.from(swapResponse.transactionMessageBase64, "base64");
      const message = VersionedMessage.deserialize(handoff);
      const transaction = new VersionedTransaction(message);

      // User signs
      transaction.sign([userKeypair]);
      const userSignature = transaction.signatures![1];
      expect(transaction.signatures).toHaveLength(2);
      expect(userSignature).toBeDefined();

      // Convert raw signature to base64
      const base64Signature = Buffer.from(userSignature!).toString("base64");

      // --- End Simulating Mock Privy Interaction ---

      const result = await tubService.signAndSendTransaction(
        mockJwtToken,
        base64Signature,
        swapResponse.transactionMessageBase64, // Send original unsigned transaction
      );

      console.log("Transaction result:", result);

      expect(result).toBeDefined();
      expect(result.signature).toBeDefined();
    };
    it.skip("should complete a USDC to SOL swap", async () => {
      console.log("\nStarting USDC to SOL swap flow test");
      console.log("User public key:", userKeypair.publicKey.toBase58());

      // Get the constructed swap transaction
      console.log("\nGetting 1 USDC to SOL swap transaction...");

      const swapResponse = await tubService.fetchSwap(mockJwtToken, {
        buyTokenId: SOL_MAINNET_PUBLIC_KEY.toString(),
        sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
        sellQuantity: 1e6 / 1000, // 0.001 USDC
        slippageBps: undefined,
      });

      await executeTx(swapResponse);
    }, 11000);

    describe.skip("MEMECOIN swaps", () => {
      it.skip("should complete a USDC to MEMECOIN swap", async () => {
        // Get swap instructions
        const swapResponse = await tubService.fetchSwap(mockJwtToken, {
          buyTokenId: MEMECOIN_MAINNET_PUBLIC_KEY.toString(),
          sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
          sellQuantity: 1e6, // 1 USDC
          slippageBps: undefined,
        });

        await executeTx(swapResponse);
      }, 13000);

      it.skip("should transfer half of held MEMECOIN to USDC", async () => {
        const userMEMECOINAta = await getAssociatedTokenAddress(MEMECOIN_MAINNET_PUBLIC_KEY, userKeypair.publicKey);
        const memecoinBalance = await connection.getTokenAccountBalance(userMEMECOINAta, "processed");
        const decimals = memecoinBalance.value.decimals;
        console.log("MEMECOIN balance:", memecoinBalance.value.uiAmount);
        if (!memecoinBalance.value.uiAmount) {
          console.log("MEMECOIN balance is 0, skipping transfer");
          return;
        }

        const balanceToken = memecoinBalance.value.uiAmount * 10 ** decimals;
        const swap = {
          buyTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
          sellTokenId: MEMECOIN_MAINNET_PUBLIC_KEY.toString(),
          sellQuantity: Math.round(balanceToken / 2),
          slippageBps: 100,
        };
        console.log("MEMECOIN swap:", swap);
        const swapResponse = await tubService.fetchSwap(mockJwtToken, swap);

        await executeTx(swapResponse);
      }, 11000);

      it.skip("should transfer all held MEMECOIN to USDC and close the MEMECOIN account", async () => {
        // wait for 10 seconds and console log the countdown
        for (let i = 10; i > 0; i--) {
          console.log(`Waiting for ${i} seconds...`);
          await new Promise((resolve) => setTimeout(resolve, 1000));
        }
        const userMemecoinAta = await getAssociatedTokenAddress(MEMECOIN_MAINNET_PUBLIC_KEY, userKeypair.publicKey);
        const memecoinBalance = await connection.getTokenAccountBalance(userMemecoinAta, "processed");

        const decimals = memecoinBalance.value.decimals;
        console.log("Memecoin balance:", memecoinBalance.value.uiAmount);
        if (!memecoinBalance.value.uiAmount) {
          console.log("Memecoin balance is 0, skipping transfer");
          return;
        }

        const initSolBalanceinMemecoinAta = await connection.getBalance(userMemecoinAta, "processed");
        if (!memecoinBalance.value.uiAmount && initSolBalanceinMemecoinAta === 0) {
          console.log("Memecoin ATA appears closed, skipping test");
          return;
        }

        const balanceToken = memecoinBalance.value.uiAmount * 10 ** decimals;
        const swap = {
          buyTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
          sellTokenId: MEMECOIN_MAINNET_PUBLIC_KEY.toString(),
          sellQuantity: Math.round(balanceToken),
          slippageBps: undefined,
        };
        console.log("Memecoin swap:", swap);
        const swapResponse = await tubService.fetchSwap(mockJwtToken, swap);
        // delay for 2 seconds
        await new Promise((resolve) => setTimeout(resolve, 2000));

        await executeTx(swapResponse);

        // wait 5 extra seconds for the transaction to be processed by most nodes
        await new Promise((resolve) => setTimeout(resolve, 5000));

        // get balance of SOL in the Memecoin account
        const memecoinSolBalanceLamports = await connection.getBalance(userMemecoinAta, "processed");
        console.log("Memecoin SOL balance lamports:", memecoinSolBalanceLamports);
        expect(memecoinSolBalanceLamports).toBe(0);
      }, 30000);
    });
  });
});
