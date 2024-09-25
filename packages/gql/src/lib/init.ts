import { cacheExchange, Client, fetchExchange } from "@urql/core";
import { initGraphQLTada } from "gql.tada";

import { introspection } from "./graphql-env";

export const client = new Client({
  url: process.env.GRAPHQL_URL!,
  fetchOptions: {
    headers: {
      "x-hasura-admin-secret": process.env.HASURA_ADMIN_SECRET!,
    },
  },
  exchanges: [cacheExchange, fetchExchange],
});

export const graphql = initGraphQLTada<{
  introspection: introspection;
  scalars: {
    uuid: string;
    bigint: bigint;
    numeric: string;
  };
}>();
