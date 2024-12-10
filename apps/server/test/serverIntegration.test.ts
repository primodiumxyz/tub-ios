import { PrivyClient } from "@privy-io/server-auth";
import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { config } from "dotenv";
import { beforeAll, describe, afterAll } from "vitest";
import WebSocket from "ws";
import { parseEnv } from "../bin/parseEnv";
import { AppRouter } from "../src/createAppRouter";
import { resolve } from "path";

const envPath = resolve(__dirname, "../../../.env");
console.log("Loading .env file from:", envPath);
config({ path: envPath });
const env = parseEnv();
const host = env.SERVER_HOST || "0.0.0.0";
const port = env.SERVER_PORT || "8888";

describe.skip("Server Integration Tests", () => {
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
});
