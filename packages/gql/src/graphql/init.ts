import { initGraphQLTada } from "gql.tada";

import { introspection } from "./codegen/graphql-env";

export const graphql = initGraphQLTada<{
  introspection: introspection;
  scalars: {
    uuid: string;
    bigint: string;
    numeric: string;
    timestamp: Date;
    timestamptz: Date;
    float8: string;
    interval: string;
  };
}>();
