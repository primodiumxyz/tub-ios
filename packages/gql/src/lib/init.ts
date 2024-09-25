import { cacheExchange, Client, fetchExchange } from "@urql/core";
import { initGraphQLTada } from "gql.tada";

import { introspection } from "./graphql-env";

export const createClient = ({ url, hasuraAdminSecret }: { url: string; hasuraAdminSecret?: string }) => {
  const fetchOptions = hasuraAdminSecret
    ? {
        headers: {
          "x-hasura-admin-secret": hasuraAdminSecret,
        },
      }
    : undefined;
  return new Client({
    url,
    fetchOptions,
    exchanges: [cacheExchange, fetchExchange],
  });
};

export const graphql = initGraphQLTada<{
  introspection: introspection;
  scalars: {
    uuid: string;
    bigint: bigint;
    numeric: string;
  };
}>();
