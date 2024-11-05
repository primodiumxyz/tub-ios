import { PrivyClient } from "@privy-io/server-auth";
import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { config } from "dotenv";
import { beforeAll, describe, expect, it } from "vitest";
import WebSocket from "ws";
import { parseEnv } from "../bin/parseEnv";
import { server } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";

config({ path: "../../../.env" });
const env = parseEnv();

describe("Coinbase Solana Onramp URL Test", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;
  const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);

  beforeAll(async () => {
    const address = server.server.address();

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
            },
          }),
        }),
      ],
    });
  });

  it("should return a URL starting with the Coinbase onramp URL", async () => {
    const expectedUrlStart = "https://pay.coinbase.com/landing\\?sessionToken=";

    // Await the result since getCoinbaseSolanaOnrampUrl is async
    const result = await client.getCoinbaseSolanaOnrampUrl.mutate();
    expect(result.coinbaseToken).toHaveLength(48);
    expect(result.url).toMatch(new RegExp(`^${expectedUrlStart}`));
  });
});
