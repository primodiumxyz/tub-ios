import { GqlClient, createClient } from "../../src/index";
import { insertMockTradeHistory } from "../lib/mock";

const DEFAULT_TRADES_AMOUNT = 700_000; // ~400 trades per second
const DEFAULT_START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago

interface BenchmarkSetupOptions {
  tradesAmount?: number;
  startDate?: Date;
}

export class BenchmarkEnvironment {
  public gqlCached: GqlClient;
  public gqlNoCache: GqlClient;
  private tokenMints: string[] = [];

  constructor() {}

  async setup(options: BenchmarkSetupOptions = {}) {
    const { tradesAmount = DEFAULT_TRADES_AMOUNT, startDate = DEFAULT_START_DATE } = options;

    this.gqlCached = await createClient({
      url: "http://localhost:8090/v1/graphql",
      hasuraAdminSecret: "password",
    });
    this.gqlNoCache = await createClient({
      url: "http://localhost:8080/v1/graphql",
      hasuraAdminSecret: "password",
    });

    this.tokenMints = await insertMockTradeHistory(this.gqlCached, {
      count: tradesAmount,
      from: startDate,
      onProgress: (inserted, total) => {
        console.log(`Inserting mock data: ${((inserted / total) * 100).toFixed(2)}%`);
      },
    });

    return this.tokenMints;
  }

  async cleanup() {
    console.log("Cleaning up benchmark data...");
    await this.gqlCached.db.DeleteTradeHistoryManyBeforeMutation({
      before: new Date(),
    });
  }

  getTokenMints() {
    return this.tokenMints;
  }
}
