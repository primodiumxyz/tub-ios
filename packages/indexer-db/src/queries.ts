import * as queries from '../../gql/src/timescale/queries/index';
import { IndexerClient, IndexerConfig } from './client';
import { PreparedQuery } from '@pgtyped/runtime';

export function registerQueries(client: IndexerClient) {
  Object.entries(queries).forEach(([name, query]) => {
    client.registerQuery(name, query as PreparedQuery<any, any>);
  });
  return client;
}

export const createClient = (config: IndexerConfig) => {
  const client = new IndexerClient(config);
  return registerQueries(client);
};
