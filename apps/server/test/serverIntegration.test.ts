import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import WebSocket from "ws";
import { server, start } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";
import { parseEnv } from "../bin/parseEnv";
import { PrivyClient } from "@privy-io/server-auth";
import { config } from "dotenv";

config({ path: "../../../.env" });
const env = parseEnv();
const tokenId = "722e8490-e852-4298-a250-7b0a399fec57";

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;
  const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);


  beforeAll(async () => {
    await start();
    const address = server.server.address();
    env

    const port = typeof address === "string" ? address : address?.port;
    const wsClient = createWSClient({
      url: `ws://localhost:${port}/trpc`,
      WebSocket: WebSocket as any,
    });

    client = createTRPCProxyClient<AppRouter>({
      links: [
        splitLink({
          condition: (op) => op.type === "subscription",
          true: wsLink({ client: wsClient }),
          false: httpBatchLink({
            url: `http://localhost:${port}/trpc`,
            headers: {
              Authorization: `Bearer ${(await privy.getTestAccessToken()).accessToken}`,
            }
          }),
        }),
      ],
    });
  });

  afterAll(async () => {
    server.close();
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
      overridePrice: "1000000000",
    });

    expect(result).toBeDefined();
  });

  it("should sell tokens", async () => {
    const result = await client.sellToken.mutate({
      tokenId,
      amount: "100",
    });

    expect(result).toBeDefined();
  });
});
