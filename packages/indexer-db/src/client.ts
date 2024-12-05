import { Pool, PoolConfig } from 'pg';
import { PreparedQuery } from '@pgtyped/runtime';

export interface IndexerConfig {
  host?: string;
  port?: number;
  database?: string;
  user?: string;
  password: string;
  ssl?: boolean;
}

type QueryFunction<P, R> = (params: P) => Promise<R[]>;

function createQueryWrapper<P, R>(
  pool: Pool,
  query: PreparedQuery<P, R>,
): QueryFunction<P, R> {
  return async (params: P) => {
    return query.run(params, pool);
  };
}

export class IndexerClient {
  private pool: Pool;
  db: Record<string, QueryFunction<any, any>> = {};

  constructor(config: IndexerConfig) {
    const poolConfig: PoolConfig = {
      host: config.host || 'localhost',
      port: config.port || 5433,
      database: config.database || 'indexer',
      user: config.user || 'indexer_user',
      password: config.password,
      ssl: config.ssl ? { rejectUnauthorized: true } : false,
    };

    this.pool = new Pool(poolConfig);
  }

  registerQuery<P, R>(name: string, query: PreparedQuery<P, R>) {
    this.db[name] = createQueryWrapper(this.pool, query);
  }

  async close() {
    await this.pool.end();
  }
}

export const createClient = (config: IndexerConfig) => {
  return new IndexerClient(config);
};
