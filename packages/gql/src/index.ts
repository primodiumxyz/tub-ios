import {
  cacheExchange,
  Client,
  fetchExchange,
  OperationContext,
  OperationResult,
  OperationResultSource,
  subscriptionExchange,
} from "@urql/core";
import { TadaDocumentNode } from "gql.tada";
import { createClient as createWSClient } from "graphql-ws";
import { WebSocket } from "ws";

import * as mutations from "./graphql/mutations";
import * as queries from "./graphql/queries";
import * as subscriptions from "./graphql/subscriptions";

/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/ban-ts-comment */

/* ---------------------------------- TYPES --------------------------------- */
// Helper type to extract variables from a query or mutation
type ExtractVariables<T> = T extends TadaDocumentNode<any, infer V, any> ? V : never;

// Helper type to extract the data shape from a query or mutation
type ExtractData<T> = T extends TadaDocumentNode<infer D, any, any> ? D : never;

// Helper type to make args optional if they're an empty object
type OptionalArgs<T> = T extends Record<string, never> ? [] | [T] : [T];

/* ---------------------------------- WRAPPERS --------------------------------- */
/**
 * Wrapper creator for queries.
 *
 * Note: This wrapper allows for optional headers to be added to all requests.
 *
 * @param client - The GraphQL client instance
 * @param operation - The operation to wrap
 * @param headers - Optional headers to add to the request
 * @returns A function that wraps the operation and returns a promise
 */
function createQueryWrapper<T extends TadaDocumentNode<any, any, any>>(
  client: Client,
  operation: T,
  headers?: Record<string, string>,
) {
  return (args: ExtractVariables<T>, options: Partial<OperationContext>): Promise<OperationResult<ExtractData<T>>> => {
    options = options ?? {};
    return client
      .query(
        operation,
        args ?? {},
        headers
          ? {
              ...options,
              fetchOptions: {
                ...(options.fetchOptions ?? {}),
                headers: {
                  ...(options.fetchOptions && "headers" in options.fetchOptions ? options.fetchOptions.headers : {}),
                  ...headers,
                },
              },
            }
          : options,
      )
      .toPromise();
  };
}

/**
 * Wrapper creator for mutations.
 *
 * @param client - The GraphQL client instance
 * @param operation - The operation to wrap
 * @returns A function that wraps the operation and returns a promise
 */
function createMutationWrapper<T extends TadaDocumentNode<any, any, any>>(client: Client, operation: T) {
  return (args: ExtractVariables<T>, options: Partial<OperationContext>): Promise<OperationResult<ExtractData<T>>> =>
    client.mutation(operation, args ?? {}, options).toPromise();
}

/**
 * Wrapper creator for subscriptions.
 *
 * @param client - The GraphQL client instance
 * @param operation - The operation to wrap
 * @returns A function that wraps the operation and returns a promise
 */
function createSubscriptionWrapper<T extends TadaDocumentNode<any, any, any>>(client: Client, operation: T) {
  return (
    args: ExtractVariables<T>,
    options: Partial<OperationContext>,
  ): OperationResultSource<OperationResult<ExtractData<T>>> => client.subscription(operation, args ?? {}, options);
}

/* ---------------------------------- TYPES --------------------------------- */
type QueryOperations = typeof queries;
type MutationOperations = typeof mutations;
type SubscriptionOperations = typeof subscriptions;

type QueryWrapperReturnType<T extends keyof QueryOperations> = ReturnType<
  ReturnType<typeof createQueryWrapper<QueryOperations[T]>>
>;

type MutationWrapperReturnType<T extends keyof MutationOperations> = ReturnType<
  ReturnType<typeof createMutationWrapper<MutationOperations[T]>>
>;

type SubscriptionWrapperReturnType<T extends keyof SubscriptionOperations> = ReturnType<
  ReturnType<typeof createSubscriptionWrapper<SubscriptionOperations[T]>>
>;

/** The queries defined in `src/graphql/queries.ts` */
type Queries = {
  [K in keyof QueryOperations]: (
    ...args: [...OptionalArgs<ExtractVariables<QueryOperations[K]>>, Partial<OperationContext>?]
  ) => QueryWrapperReturnType<K>;
};

/** The mutations defined in `src/graphql/mutations.ts` */
type Mutations = {
  [K in keyof MutationOperations]: (
    ...args: [...OptionalArgs<ExtractVariables<MutationOperations[K]>>, Partial<OperationContext>?]
  ) => MutationWrapperReturnType<K>;
};

/** The subscriptions defined in `src/graphql/subscriptions.ts` */
type Subscriptions = {
  [K in keyof SubscriptionOperations]: (
    ...args: [...OptionalArgs<ExtractVariables<SubscriptionOperations[K]>>, Partial<OperationContext>?]
  ) => SubscriptionWrapperReturnType<K>;
};

/**
 * An object containing a client instance and the database object.
 *
 * The database object allows for interacting with the database with full type-safety, according to the schema inferred
 * from the GraphQL operations.
 *
 * @property {Client} instance - The GraphQL client instance
 * @property {Queries & Mutations & Subscriptions} db - The database object that can be used to conveniently perform
 *   queries, mutations and subscriptions
 */
type GqlClient = {
  instance: Client;
  db: Queries & Mutations & Subscriptions;
};

/**
 * Type of the return value of the `createClient` function.
 *
 * In a web environment, the client is returned synchronously. In a node environment, the client is returned
 * asynchronously, as the `ws` package needs to be imported dynamically.
 *
 * @template T - The environment the client is running in ("web" or "node")
 */
type CreateClientReturn<T extends "web" | "node"> = T extends "web" ? GqlClient : Promise<GqlClient>;

/* ---------------------------------- CLIENT --------------------------------- */

/**
 * Creates a GraphQL client instance.
 *
 * If the client is running in a node environment, the `ws` package needs to be imported dynamically so it will return a
 * promise.
 *
 * @template T - The environment the client is running in ("web" or "node")
 * @param options - The options for the client
 * @param options.url - The URL of the GraphQL endpoint
 * @param options.hasuraAdminSecret - The Hasura admin secret
 * @param options.headers - Optional headers to add to queries requests
 * @returns A {@link GqlClient} instance
 */
const createClient = <T extends "web" | "node" = "node">({
  url,
  hasuraAdminSecret,
  headers,
}: {
  url: string;
  hasuraAdminSecret?: string;
  headers?: Record<string, string>;
}): CreateClientReturn<T> => {
  // Add the admin secret to the fetch options if it's provided
  const fetchOptions = hasuraAdminSecret
    ? {
        headers: {
          "x-hasura-admin-secret": hasuraAdminSecret,
          ...headers,
        },
      }
    : undefined;

  // Create the client instance
  const createClientInternal = (webSocketImpl?: typeof WebSocket): GqlClient => {
    const wsClient = createWSClient({
      url: url.replace("https", "wss").replace("8090", "8080"),
      webSocketImpl,
    });

    const client = new Client({
      url,
      fetchOptions,
      exchanges: [
        cacheExchange,
        fetchExchange,
        subscriptionExchange({
          forwardSubscription(request) {
            const input = { ...request, query: request.query || "" };
            return {
              subscribe(sink) {
                const unsubscribe = wsClient.subscribe(input, sink);
                return { unsubscribe };
              },
            };
          },
        }),
      ],
    });

    // Create the db objects dynamically
    const _queries = Object.entries(queries).reduce((acc, [key, operation]) => {
      // @ts-ignore
      acc[key as keyof Queries] = createQueryWrapper(client, operation, headers);
      return acc;
    }, {} as Queries);

    const _mutations = Object.entries(mutations).reduce((acc, [key, operation]) => {
      // @ts-ignore
      acc[key as keyof Mutations] = createMutationWrapper(client, operation);
      return acc;
    }, {} as Mutations);

    const _subscriptions = Object.entries(subscriptions).reduce((acc, [key, operation]) => {
      // @ts-ignore
      acc[key as keyof Subscriptions] = createSubscriptionWrapper(client, operation);
      return acc;
    }, {} as Subscriptions);

    return {
      instance: client,
      db: {
        ..._queries,
        ..._mutations,
        ..._subscriptions,
      },
    };
  };

  // @ts-ignore
  if (typeof window !== "undefined") return createClientInternal() as CreateClientReturn<T>;
  return import("ws").then(({ WebSocket }) => createClientInternal(WebSocket)) as CreateClientReturn<T>;
};

export { createClient, queries, mutations, subscriptions };
export type { GqlClient, Queries, Mutations, Subscriptions };
