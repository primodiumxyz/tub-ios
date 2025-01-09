import { afterAll, beforeAll, describe, it } from "vitest";
import { createClient, GqlClient } from "../../src/index";
import { insertMockTradeHistory } from "../lib/mock";

const TRADES_AMOUNT = 700_000; // ~400 trades per second
const START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago

describe("GetTopTokensByVolume benchmarks", () => {
  let gqlCached: GqlClient;
  // let gqlNoCache: GqlClient;
  // let tokenMints: string[];

  beforeAll(async () => {
    gqlCached = await createClient({
      url: "http://localhost:8090/v1/graphql",
      hasuraAdminSecret: "password",
    });
    gqlCached = await createClient({
      url: "http://localhost:8080/v1/graphql",
      hasuraAdminSecret: "password",
    });

    tokenMints = await insertMockTradeHistory(gqlCached, {
      count: TRADES_AMOUNT,
      from: START_DATE,
      onProgress: (inserted, total) => {
        console.log(`Inserting mock data: ${((inserted / total) * 100).toFixed(2)}%`);
      },
    });
  });

  it("query last 5 minutes", async () => {
    // ...
  });

  afterAll(async () => {
    // Clean up data used for benchmarks
    console.log("Cleaning up data used for benchmarks");
    await gqlCached.db.DeleteTradeHistoryManyBeforeMutation({
      before: new Date(),
    });
  });
});
