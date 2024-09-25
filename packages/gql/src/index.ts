import { TadaDocumentNode } from "gql.tada";
import { client } from "./lib/init";
import * as mutations from "./lib/mutations";
import * as queries from "./lib/queries";
import { OperationResult } from "@urql/core";

// Helper type to extract variables from a query or mutation
type ExtractVariables<T> = T extends TadaDocumentNode<any, infer V, any> ? V : never;

// Helper type to extract the data shape from a query or mutation
type ExtractData<T> = T extends TadaDocumentNode<infer D, any, any> ? D : never;

// Helper type to make args optional if they're an empty object
type OptionalArgs<T> = T extends Record<string, never> ? [] | [T] : [T];

// Wrapper creator for both queries and mutations
function createQueryWrapper<T extends TadaDocumentNode<any, any, any>>(operation: T) {
  return (args: ExtractVariables<T>): Promise<OperationResult<ExtractData<T>>> => 
    client.query(operation, args ?? {}).toPromise();
}

function createMutationWrapper<T extends TadaDocumentNode<any, any, any>>(operation: T) {
  return (args: ExtractVariables<T>): Promise<OperationResult<ExtractData<T>>> => 
    client.mutation(operation, args ?? {}).toPromise();
}

type AllOperations = typeof queries & typeof mutations;
// Helper type to get the return type of createWrapper for a specific operation
type WrapperReturnType<T extends keyof AllOperations> = 
  ReturnType<ReturnType<typeof createQueryWrapper<AllOperations[T]>>>;

// Define the db object type with specific return types for each operation
type DbType = {
  [K in keyof AllOperations]: (
    ...args: OptionalArgs<ExtractVariables<AllOperations[K]>>
  ) => WrapperReturnType<K>;
};

// Create the db object dynamically
const _queries = Object.entries(queries).reduce((acc, [key, operation]) => {
  // @ts-ignore
  acc[key as keyof DbType] = createQueryWrapper(operation);
  return acc;
}, {} as DbType);


// Create the db object dynamically
const _mutations = Object.entries(mutations).reduce((acc, [key, operation]) => {
  // @ts-ignore
  acc[key as keyof DbType] = createMutationWrapper(operation);
  return acc;
}, {} as DbType);


const db = {
  ..._queries,
  ..._mutations,
};


export { client, db, queries };
