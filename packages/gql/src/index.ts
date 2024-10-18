import {
  cacheExchange,
  Client,
  fetchExchange,
  OperationResult,
  OperationResultSource,
  subscriptionExchange,
} from "@urql/core";
import { TadaDocumentNode } from "gql.tada";
import { createClient as createWSClient } from "graphql-ws";
import { WebSocket } from "ws";

import * as mutations from "./lib/mutations";
import * as queries from "./lib/queries";
import * as subscriptions from "./lib/subscriptions";

// Helper type to extract variables from a query or mutation
type ExtractVariables<T> = T extends TadaDocumentNode<any, infer V, any> ? V : never;

// Helper type to extract the data shape from a query or mutation
type ExtractData<T> = T extends TadaDocumentNode<infer D, any, any> ? D : never;

// Helper type to make args optional if they're an empty object
type OptionalArgs<T> = T extends Record<string, never> ? [] | [T] : [T];

//------------------------------------------------

// Wrapper creator for both queries and mutations
function createQueryWrapper<T extends TadaDocumentNode<any, any, any>>(client: Client, operation: T) {
  return (args: ExtractVariables<T>): Promise<OperationResult<ExtractData<T>>> =>
    client.query(operation, args ?? {}).toPromise();
}

function createMutationWrapper<T extends TadaDocumentNode<any, any, any>>(client: Client, operation: T) {
  return (args: ExtractVariables<T>): Promise<OperationResult<ExtractData<T>>> =>
    client.mutation(operation, args ?? {}).toPromise();
}

function createSubscriptionWrapper<T extends TadaDocumentNode<any, any, any>>(client: Client, operation: T) {
  return (args: ExtractVariables<T>): OperationResultSource<OperationResult<ExtractData<T>>> =>
    client.subscription(operation, args ?? {});
}

//------------------------------------------------

type QueryOperations = typeof queries;
type MutationOperations = typeof mutations;
type SubscriptionOperations = typeof subscriptions;

//------------------------------------------------

type QueryWrapperReturnType<T extends keyof QueryOperations> = ReturnType<
  ReturnType<typeof createQueryWrapper<QueryOperations[T]>>
>;

type MutationWrapperReturnType<T extends keyof MutationOperations> = ReturnType<
  ReturnType<typeof createMutationWrapper<MutationOperations[T]>>
>;

type SubscriptionWrapperReturnType<T extends keyof SubscriptionOperations> = ReturnType<
  ReturnType<typeof createSubscriptionWrapper<SubscriptionOperations[T]>>
>;

//------------------------------------------------

export type Queries = {
  [K in keyof QueryOperations]: (
    ...args: OptionalArgs<ExtractVariables<QueryOperations[K]>>
  ) => QueryWrapperReturnType<K>;
};
export type Mutations = {
  [K in keyof MutationOperations]: (
    ...args: OptionalArgs<ExtractVariables<MutationOperations[K]>>
  ) => MutationWrapperReturnType<K>;
};
export type Subscriptions = {
  [K in keyof SubscriptionOperations]: (
    ...args: OptionalArgs<ExtractVariables<SubscriptionOperations[K]>>
  ) => SubscriptionWrapperReturnType<K>;
};

export type GqlClient = {
  instance: Client;
  db: Queries & Mutations & Subscriptions;
};

//------------------------------------------------

type CreateClientReturn<T extends "web" | "node"> = T extends "web" ? GqlClient : Promise<GqlClient>;
const createClient = <T extends "web" | "node" = "node">({
  url,
  hasuraAdminSecret,
}: {
  url: string;
  hasuraAdminSecret?: string;
}): CreateClientReturn<T> => {
  const fetchOptions = hasuraAdminSecret
    ? {
      headers: {
        "x-hasura-admin-secret": hasuraAdminSecret,
      },
    }
    : undefined;

  const createClientInternal = (webSocketImpl?: typeof WebSocket): GqlClient => {
    const wsClient = createWSClient({
      url: url.replace("https", "wss"),
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

    // Create the db object dynamically
    const _queries = Object.entries(queries).reduce((acc, [key, operation]) => {
      // @ts-ignore
      acc[key as keyof Queries] = createQueryWrapper(client, operation);
      return acc;
    }, {} as Queries);

    // Create the db object dynamically
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

  if (typeof window !== "undefined") return createClientInternal() as CreateClientReturn<T>;
  return import("ws").then(({ WebSocket }) => createClientInternal(WebSocket)) as CreateClientReturn<T>;
};

export { createClient, queries, mutations, subscriptions };
