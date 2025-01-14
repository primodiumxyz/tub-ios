import { insertMockTradeHistory } from "../../lib/mock";
import { createClientNoCache } from "../../lib/common";
import fs from "fs";
import { TRADES_AMOUNT, START_DATE } from "../config";

const seed = async () => {
  console.log("Starting seed process...");
  const client = await createClientNoCache();

  // Insert mock trade history
  await insertMockTradeHistory(client, {
    count: TRADES_AMOUNT,
    from: START_DATE,
    onProgress: (inserted, total) => {
      console.log(`Seeding progress: ${((inserted / total) * 100).toFixed(2)}%`);
    },
  });

  // Get top tokens for testing
  console.log("Fetching top tokens...");
  const res = await client.db.GetTopTokensByVolumeQuery({
    interval: "30m",
    recentInterval: "20s",
  });

  if (!res.data?.token_stats_interval_comp.length) {
    throw new Error("No tokens found after seeding");
  }

  const tokens = res.data.token_stats_interval_comp.map((t) => t.token_mint);
  console.log(`Found ${tokens.length} tokens for testing`);

  // Save tokens for k6 tests
  const outputPath = "./__test__/k6/output/tokens.json";
  fs.writeFileSync(outputPath, JSON.stringify(tokens, null, 2));
  console.log(`Tokens saved to ${outputPath}`);

  return tokens;
};

seed()
  .then(() => {
    console.log("Mock data inserted & tokens saved");
    process.exit(0);
  })
  .catch((e) => {
    console.error("Error inserting mock data", e);
    process.exit(1);
  });
