import { PrivyClient } from "@privy-io/server-auth";
import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { config } from "dotenv";
import { beforeAll, describe, expect, inject, it } from "vitest";
import WebSocket from "ws";
import { parseEnv } from "../bin/parseEnv";
import { AppRouter } from "../src/createAppRouter";
import { resolve } from 'path';

const envPath = resolve(__dirname, "../../../.env");
console.log("Loading .env file from:", envPath);
config({ path: envPath });
const env = parseEnv();
const tokenId = "722e8490-e852-4298-a250-7b0a399fec57";
const host = process.env.SERVER_HOST || 'localhost';
const port = process.env.SERVER_PORT || '4000';

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;
  const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);

  beforeAll(async () => {
    const wsUrl = `ws://${host}:${port}/trpc`;
    console.log(`Connecting to WebSocket at: ${wsUrl}`);
    
    const wsClient = createWSClient({
      url: wsUrl,
      WebSocket: WebSocket as any,
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
