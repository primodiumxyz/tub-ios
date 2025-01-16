import { insertMockTradeHistory } from "../../lib/mock";
import { createClientNoCache } from "../../lib/common";
import fs from "fs";

// Amount of trades to generate when seeding
const TRADES_AMOUNT = 100; // ~500 trades per second
// Period over which trades are generated
const START_DATE = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago

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

  // Refresh view
  const refreshRes = await client.db.RefreshTokenRollingStats30MinMutation();
  if (refreshRes.error || !refreshRes.data?.api_refresh_token_rolling_stats_30min?.success) {
    throw new Error(`Failed to refresh token rolling stats: ${refreshRes.error?.message ?? "Unknown error"}`);
  }

  // Get top tokens for testing
  console.log("Fetching top tokens...");
  const tokensRes = await client.db.GetTopTokensByVolumeQuery({});

  if (tokensRes.error || !tokensRes.data?.token_rolling_stats_30min.length) {
    throw new Error(`No tokens found after seeding: ${tokensRes.error?.message ?? "Unknown error"}`);
  }

  const tokens = tokensRes.data.token_rolling_stats_30min.map((t) => t.mint);
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
