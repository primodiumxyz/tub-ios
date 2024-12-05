import { PrivyClient } from "@privy-io/server-auth";
import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { config } from "dotenv";
import { beforeAll, describe, expect, it, afterAll } from "vitest";
import WebSocket from "ws";
import { parseEnv } from "../bin/parseEnv";
import { AppRouter } from "../src/createAppRouter";
import { resolve } from "path";
import { Keypair, Transaction } from "@solana/web3.js";
import bs58 from "bs58";

const envPath = resolve(__dirname, "../../../.env");
console.log("Loading .env file from:", envPath);
config({ path: envPath });
const env = parseEnv();
const tokenId = "722e8490-e852-4298-a250-7b0a399fec57";
const host = process.env.SERVER_HOST || "0.0.0.0";
const port = process.env.SERVER_PORT || "8888";

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;
  let wsClient: ReturnType<typeof createWSClient>;
  const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);

  beforeAll(async () => {
    const wsUrl = `ws://${host}:${port}/trpc`;
    console.log(`Connecting to WebSocket at: ${wsUrl}`);

    wsClient = createWSClient({
      url: `ws://${host}:${port}/trpc`,
      // @ts-expect-error WebSocket is not typed
      WebSocket,
    });

    client = createTRPCProxyClient<AppRouter>({
      links: [
        splitLink({
          condition: (op) => op.type === "subscription",
          true: wsLink({ client: wsClient }),
          false: httpBatchLink({
            url: `http://${host}:${port}/trpc`,
            headers: {
              Authorization: `Bearer ${(await privy.getTestAccessToken()).accessToken}`,
            },
          }),
        }),
      ],
    });
  });

  afterAll(async () => {
    try {
      // Close all subscriptions and queries
      if (client) {
        // @ts-expect-error _client is internal but needed for cleanup
        await client._client?.terminate?.();
        // @ts-expect-error _subscriptions is internal but needed for cleanup
        client._subscriptions?.forEach((sub) => sub.unsubscribe?.());
      }

      // Close the WebSocket client
      if (wsClient) {
        wsClient.close();
      }

      // Small delay to ensure all connections are properly closed
      await new Promise((resolve) => setTimeout(resolve, 500));
    } catch (error) {
      console.error("Error in test cleanup:", error);
    }
  });

  describe("Mock Api Endpoints", () => {
    it("should get status", async () => {
      const result = await client.getStatus.query();
      expect(result).toEqual({ status: 200 });
    });

    it("should airdrop tokens to a user", async () => {
      const _result = await client.airdropNativeToUser.mutate({
        amount: "1000000000000000000",
      });

      const id = _result?.insert_wallet_transaction_one?.id;

      expect(id).toBeDefined();
    });

    it("should buy tokens", async () => {
      const result = await client.buyToken.mutate({
        tokenId,
        amount: "100",
        tokenPrice: "1000000000",
      });

      expect(result).toBeDefined();
    });

    it("should sell tokens", async () => {
      const result = await client.sellToken.mutate({
        tokenId,
        amount: "100",
        tokenPrice: "1000000000",
      });

      expect(result).toBeDefined();
    });

    it("should record client events", async () => {
      const result = await client.recordClientEvent.mutate({
        userAgent: "test",
        eventName: "test",
        source: "test",
        metadata: JSON.stringify({
          test: "test",
        }),
        errorDetails: "test",
      });

      expect(result).toBeDefined();
    });

    it("should request a Codex API token", async () => {
      const result = await client.requestCodexToken.mutate({
        expiration: 3600 * 1000,
      });

      expect(result).toBeDefined();
    });
  });
  describe("getPresignedTransfer", () => {
    // privy dev key
    const fromAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";
    // fee payer address
    const toAddress = "2HpAnS4sSbJaYxjETSE9uMtnuvja3hJsGqQZynmmWwfa";
    const usdcTokenId = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";

    it("should execute getPresignedTransfer and verify fee payer", async () => {
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));
      const result = await client.getSignedTransfer.mutate({
        fromAddress,
        toAddress,
        amount: String(1e5),
        tokenId: usdcTokenId,
      });

      expect(result).toBeDefined();
      const transactionBase64 = result.transactionBase64;
      const transactionBuffer = Buffer.from(transactionBase64, "base64");
      const transaction = Transaction.from(transactionBuffer);

      // Verify that the fee payer matches
      expect(transaction.feePayer?.toBase58()).toEqual(feePayerKeypair.publicKey.toBase58());
    });

    it("should verify that the transaction is signed by the fee payer", async () => {
      const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));
      const result = await client.getSignedTransfer.mutate({
        fromAddress,
        toAddress,
        amount: String(1e5),
        tokenId: usdcTokenId,
      });

      expect(result).toBeDefined();

      // Verify that the transaction is signed by the fee payer
      const isSigned = result.signerBase58 === feePayerKeypair.publicKey.toBase58();
      expect(isSigned).toBe(true);
    });
  });
});
