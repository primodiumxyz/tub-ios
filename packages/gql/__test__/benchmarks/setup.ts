import { GqlClient, createClient } from "../../src/index";
import { insertMockTradeHistory } from "../lib/mock";

/* -------------------------------------------------------------------------- */
/*                            GLOBAL ENVIRONMENT                              */
/* -------------------------------------------------------------------------- */

const DEFAULT_TRADES_AMOUNT = 700_000; // ~400 trades per second
const DEFAULT_START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago

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
  public gqlCached: GqlClient;
  public gqlNoCache: GqlClient;
  private tokenMints: string[] = [];

  constructor() {}

  async setup() {
    this.gqlCached = await createClient({
      url: "http://localhost:8090/v1/graphql",
      hasuraAdminSecret: "password",
    });
    this.gqlNoCache = await createClient({
      url: "http://localhost:8080/v1/graphql",
      hasuraAdminSecret: "password",
    });

    this.tokenMints = await insertMockTradeHistory(this.gqlCached, {
      count: DEFAULT_TRADES_AMOUNT,
      from: DEFAULT_START_DATE,
      onProgress: (inserted, total) => {
        console.log(`Inserting mock data: ${((inserted / total) * 100).toFixed(2)}%`);
      },
    });

    return this.tokenMints;
  }

  getTokenMints() {
    return this.tokenMints;
  }
}
