import { insertMockTradeHistory } from "../../lib/seed";
import { createClientNoCache } from "../../lib/common";
import fs from "fs";
import path from "path";

const MOCK_TRADES = 1_000_000;
const HISTORY_WINDOW = 30 * 60 * 1000; // 30 minutes

async function seed() {
  console.log("Starting seed process...");
  const client = await createClientNoCache();

  // Insert mock trade history
  await insertMockTradeHistory(client, {
    count: MOCK_TRADES,
    from: new Date(Date.now() - HISTORY_WINDOW),
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
  const outputPath = path.join(__dirname, "../results/tokens.json");
  fs.writeFileSync(outputPath, JSON.stringify(tokens, null, 2));
  console.log(`Tokens saved to ${outputPath}`);

  return tokens;
}

seed()
  .then(() => {
    console.log("Seed process completed successfully");
  })
  .catch(console.error);
