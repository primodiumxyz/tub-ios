import { createTRPCProxyClient, CreateTRPCProxyClient, httpBatchLink } from "@trpc/client";

import type { AppRouter } from "./createAppRouter";

type CreateClientOptions = {
  /**
   * tRPC endpoint URL like `https://keeper.dev.linfra.xyz/trpc`.
   */
  url: string;
  token: string;
};

/**
 * Creates a tRPC client to talk to a server.
 *
 * @param {CreateClientOptions} options See `CreateClientOptions`.
 * @returns {CreateTRPCProxyClient<AppRouter>} A typed tRPC client.
 */
export function createClient({ url, token }: CreateClientOptions): CreateTRPCProxyClient<AppRouter> {
  return createTRPCProxyClient<AppRouter>({
    links: [
      httpBatchLink({
        url,
        // headers: {
        //   Authorization: `Bearer ${token}`,
        // },
      }),
    ],
  });
}
