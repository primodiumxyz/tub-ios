import { createTRPCProxyClient, createWSClient, httpBatchLink, splitLink, wsLink } from "@trpc/client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import WebSocket from "ws";
import { server, start } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;

  beforeAll(async () => {
    await start();
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

  it("should increment call", async () => {
    await client.incrementCall.mutate();
  });

  it("should listen to counter updates", async () => {
    const receivedValues: number[] = [];
    const subscription = client.onCounterUpdate.subscribe(undefined, {
      onData: (value) => {
        receivedValues.push(value);
      },
    });

    // Trigger a counter update
    await client.incrementCall.mutate();

    // Wait for a short time to allow the subscription to receive the update
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Unsubscribe
    subscription.unsubscribe();

    // Check received values
    expect(receivedValues.length).toBeGreaterThan(0);
    expect(receivedValues[receivedValues.length - 1]).toBeGreaterThan(0);
  });

  it("should register a new user", async () => {
    const result = await client.registerNewUser.mutate({
      username: "TEST",
      airdropAmount: "100",
    });

    expect(result).toBeDefined();
  });

  it("should airdrop tokens to a user", async () => {
    const _result = await client.registerNewUser.mutate({
      username: "TEST",
      airdropAmount: "10",
    });

    const accountId = _result?.insert_account_one?.id;

    if(!accountId) {
      throw new Error("Account ID not found");
    }

    const result = await client.airdropNativeToUser.mutate({
      accountId,
      amount: "100000",
    });

    expect(result).toBeDefined();
  });
});
