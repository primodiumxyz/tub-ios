import { initGraphQLTada } from "gql.tada";

import { introspection } from "./codegen/graphql-env";

/**
 * Transforms a GraphQL operation into a type-safe function that can be used to perform the operation.
 *
 * Define any custom scalars in the `scalars` object here.
 */
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
