import { createTRPCProxyClient, httpBatchLink } from "@trpc/client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { server, start } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";

describe("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;

  beforeAll(async () => {
    await start();
    const address = server.server.address();

    const port = typeof address === 'string' ? address : address?.port;
    client = createTRPCProxyClient<AppRouter>({
      links: [
        httpBatchLink({
          url: `http://localhost:${port}/trpc`,
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
      const result = await client.incrementCall.mutate();
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
    await new Promise((resolve) => setTimeout(resolve, 5000));

    // Unsubscribe
    subscription.unsubscribe();

    // Check received values
    expect(receivedValues.length).toBeGreaterThan(0);
    expect(receivedValues[receivedValues.length - 1]).toBeGreaterThan(0);
  });

  // Add more tests for other endpoints and functionalities
});
