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
import { PrebuildSwapResponse, SubmitSignedTransactionResponse } from "../src/types";
import { USDC_MAINNET_PUBLIC_KEY, SOL_MAINNET_PUBLIC_KEY, MEMECOIN_MAINNET_PUBLIC_KEY } from "../src/constants/tokens";
import { ConfigService } from "../src/services/ConfigService";
import { TransferService } from "@/services/TransferService";
import { TransactionService } from "@/services/TransactionService";
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

  describe.skip("SOL transfer test", () => {
    it("should transfer SOL from user to desired address", async () => {
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY)); // note that the fee payer is the destination for this test
      const transactionService = new TransactionService(connection, feePayerKeypair);
      const transferService = new TransferService(connection, feePayerKeypair, transactionService);

      const destinationKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY)); // note that the fee payer is the destination for this test
      // get user's SOL balance
      const initUserSolBalance = await connection.getBalance(userKeypair.publicKey, "processed");
      console.log("Initial user SOL balance:", initUserSolBalance);
      const transferResponse = await transferService.getTransfer({
        toAddress: destinationKeypair.publicKey.toString(),
        fromAddress: userKeypair.publicKey.toString(),
        amount: BigInt(1),
        tokenId: "SOLANA",
      });
      console.log("Transfer response:", transferResponse);
      // decode the transaction message
      const handoff = Buffer.from(transferResponse.transactionMessageBase64, "base64");
      const message = VersionedMessage.deserialize(handoff);
      const transaction = new VersionedTransaction(message);
      transaction.sign([userKeypair]);
      transaction.sign([feePayerKeypair]);
      const userSignature = transaction.signatures![1];
      const feePayerSignature = transaction.signatures![0];
      expect(transaction.signatures).toHaveLength(2);
      expect(userSignature).toBeDefined();
      expect(feePayerSignature).toBeDefined();

      // send the transaction
      const txid = await connection.sendTransaction(transaction);
      console.log("Transaction sent with id:", txid);

      // wait for 10 seconds and console log the countdown
      for (let i = 10; i > 0; i--) {
        console.log(`Let RPCs catch up for ${i} seconds...`);
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }

      // get user's SOL balance
      const userSolBalance = await connection.getBalance(userKeypair.publicKey, "processed");
      console.log("User SOL balance:", userSolBalance);
      // expect the user's SOL balance to be equal to the initial balance minus 1 lamport
      expect(userSolBalance).toEqual(initUserSolBalance - 1);
    });
  });

  describe.skip("swap execution", () => {
    const executeTx = async (swapResponse: PrebuildSwapResponse) => {
      let rebuild = false;
      let result: SubmitSignedTransactionResponse;
      do {
        rebuild = false;
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

        result = await tubService.signAndSendTransaction(
          mockJwtToken,
          base64Signature,
          swapResponse.transactionMessageBase64, // Send original unsigned transaction
        );

        console.log("Transaction result:", result);

        if (result.responseType === "rebuild" && result.rebuild) {
          console.log("Transaction rebuilt, retrying...");
          swapResponse = result.rebuild;
          rebuild = true;
          await executeTx(swapResponse);
        }
      } while (rebuild);

      expect(result).toBeDefined();
      expect(result.txid).toBeDefined();
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

    describe("MEMECOIN swaps", () => {
      it("should complete a USDC to MEMECOIN swap", async () => {
        // Get swap instructions
        const swapResponse = await tubService.fetchSwap(mockJwtToken, {
          buyTokenId: MEMECOIN_MAINNET_PUBLIC_KEY.toString(),
          sellTokenId: USDC_MAINNET_PUBLIC_KEY.toString(),
          sellQuantity: 1e6, // 1 USDC
          slippageBps: undefined,
        });

        await executeTx(swapResponse);
      }, 75000);

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
          slippageBps: undefined,
        };
        console.log("MEMECOIN swap:", swap);
        const swapResponse = await tubService.fetchSwap(mockJwtToken, swap);

        await executeTx(swapResponse);
      }, 11000);

      it("should transfer all held MEMECOIN to USDC and close the MEMECOIN account", async () => {
        // wait for 5 seconds and console log the countdown
        for (let i = 5; i > 0; i--) {
          console.log(`Let RPCs catch up for ${i} seconds...`);
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
        // delay for 1 second to emulate latency
        await new Promise((resolve) => setTimeout(resolve, 1000));

        await executeTx(swapResponse);

        // wait for 5 seconds to ensure the transaction is processed by most nodes
        for (let i = 5; i > 0; i--) {
          console.log(`Validate balance change in ${i} seconds...`);
          await new Promise((resolve) => setTimeout(resolve, 1000));
        }

        // get balance of SOL in the Memecoin account
        const memecoinSolBalanceLamports = await connection.getBalance(userMemecoinAta, "processed");
        console.log("Memecoin SOL balance lamports:", memecoinSolBalanceLamports);
        expect(memecoinSolBalanceLamports).toBe(0);
      }, 80000);
    });
  });
});
