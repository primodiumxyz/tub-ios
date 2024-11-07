import { PrivyClient } from "@privy-io/server-auth";
import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { config } from "dotenv";
import { beforeAll, describe, expect, inject, it } from "vitest";
import WebSocket from "ws";
import { parseEnv } from "../bin/parseEnv";
import { AppRouter } from "../src/createAppRouter";

config({ path: "../../../.env" });
const env = parseEnv();
const tokenId = "722e8490-e852-4298-a250-7b0a399fec57";
const port = inject("port");
const host = inject("host");

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;
  const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);

  beforeAll(async () => {
    const wsClient = createWSClient({
      url: `ws://${host}:${port}/trpc`,
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
