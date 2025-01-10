import { GqlClient, createClient } from "../../src/index";
import { insertMockTradeHistory } from "../lib/mock";

/* -------------------------------------------------------------------------- */
/*                            GLOBAL ENVIRONMENT                              */
/* -------------------------------------------------------------------------- */

// const DEFAULT_TRADES_AMOUNT = 700_000; // ~400 trades per second
const DEFAULT_TRADES_AMOUNT = 10_000;
const DEFAULT_START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago
export const ITERATIONS = 10;

let globalEnv: BenchmarkMockEnvironment | null = null;

export const getGlobalEnv = async () => {
  if (!globalEnv) {
    globalEnv = new BenchmarkMockEnvironment();
    await globalEnv.setup();
  }
  return globalEnv;
};

/* -------------------------------------------------------------------------- */
/*                                    SETUP                                   */
/* -------------------------------------------------------------------------- */

export class BenchmarkMockEnvironment {
  public defaultClient: GqlClient;
  private tokenMints: string[] = [];

  constructor() {}

  // This will create `DEFAULT_TRADES_AMOUNT` trades and insert them into the database
  // This setup is shared across all benchmarks, but every time it's run, it will create a new set of data
  // To clean up the data, you can run this query on the database:
  // DELETE FROM api_trade_history
  async setup() {
    this.defaultClient = await createClient({
      url: "http://localhost:8090/v1/graphql",
      hasuraAdminSecret: "password",
      headers: {
        "x-cache-time": "1h",
      },
    });

    this.tokenMints = await insertMockTradeHistory(this.defaultClient, {
      count: DEFAULT_TRADES_AMOUNT,
      from: DEFAULT_START_DATE,
      onProgress: (inserted, total) => {
        console.log(`Inserting mock data: ${((inserted / total) * 100).toFixed(2)}%`);
      },
    });

    return this.tokenMints;
  }

  async clearCache() {
    try {
      const response = await fetch("http://localhost:8090/flush", {
        method: "POST",
        headers: {
          "x-redis-secret": "password",
        },
      });
      if (!response.ok) throw new Error(response.statusText);
    } catch (error) {
      console.error("Failed to clear cache", error);
    }
  }

  getTokenMints() {
    return this.tokenMints;
  }
}
