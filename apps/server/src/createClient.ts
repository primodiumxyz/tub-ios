import { createTRPCProxyClient, CreateTRPCProxyClient, httpBatchLink, splitLink } from "@trpc/client";
import { createWSClient, wsLink } from '@trpc/client/links/wsLink';

import type { AppRouter } from "./createAppRouter";

type CreateClientOptions = {
  httpUrl: string;
  wsUrl: string;
};

/**
 * Creates a tRPC client to talk to a server.
 *
 * @param {CreateClientOptions} options See `CreateClientOptions`.
 * @returns {CreateTRPCProxyClient<AppRouter>} A typed tRPC client.
 */
export function createClient({ httpUrl, wsUrl }: CreateClientOptions): CreateTRPCProxyClient<AppRouter> {
  const wsClient = createWSClient({
    url: wsUrl,
  });

  return createTRPCProxyClient<AppRouter>({
    links: [
      splitLink({
        condition: (op) => op.type === 'subscription',
        true: wsLink({
          client: wsClient,
        }),
        false: httpBatchLink({
          url: httpUrl,
        }),
      }),
    ],
  });
}
