import { createTRPCProxyClient, httpBatchLink } from "@trpc/client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { server, start } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";

describe.only("Server Integration Tests", () => {
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
    await server.close();
  });

  it("should get status", async () => {
    const result = await client.getStatus.query();
    expect(result).toEqual({ status: 200 });
  });

  it("should increment call", async () => {
    try {
      const result = await client.incrementCall.mutate();
      console.log("incremented call", result);
      expect(result).toEqual('yes');
    } catch (error) {
      console.log(error);
      throw error;
    }
    // Add assertion to check if the call was incremented
    // This might involve checking the mock function in tubService
  });

  // Add more tests for other endpoints and functionalities
});
