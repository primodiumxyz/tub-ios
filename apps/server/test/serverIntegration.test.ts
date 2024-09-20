import { createTRPCProxyClient, httpBatchLink } from "@trpc/client";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { server, start } from "../bin/tub-server";
import { AppRouter } from "../src/createAppRouter";

describe.only("Server Integration Tests", () => {
  let client: ReturnType<typeof createTRPCProxyClient<AppRouter>>;

  beforeAll(async () => {
    await start();
    const port = (server.server.address() as any).port;
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
    await client.incrementCall.mutate();
    // Add assertion to check if the call was incremented
    // This might involve checking the mock function in tubService
  });

  // Add more tests for other endpoints and functionalities
});
