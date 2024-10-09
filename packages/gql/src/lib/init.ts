import { initGraphQLTada } from "gql.tada";

import { introspection } from "./graphql-env";

export const graphql = initGraphQLTada<{
  introspection: introspection;
  scalars: {
    uuid: string;
    bigint: bigint;
    numeric: string;
    timestamp: Date;
    timestamptz: Date;
  };
}>();

