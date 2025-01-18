import fs from "fs";
import { createClient } from "../../../src/index";

const fetchTokens = async () => {
  const client = await createClient({
    url: process.env.GRAPHQL_URL ?? "",
    hasuraAdminSecret: process.env.HASURA_ADMIN_SECRET ?? "",
  });

  const tokensRes = await client.db.GetTopTokensByVolumeQuery({});
  if (tokensRes.error || !tokensRes.data?.token_rolling_stats_30min.length) {
    throw new Error(`No tokens found: ${tokensRes.error?.message ?? "Unknown error"}`);
  }

  const tokens = tokensRes.data.token_rolling_stats_30min.map((t) => t.mint);

  // Save tokens for k6 tests
  const outputPath = "./__test__/k6/output/tokens.json";
  fs.writeFileSync(outputPath, JSON.stringify(tokens, null, 2));
  console.log(`Tokens saved to ${outputPath}`);
};

fetchTokens()
  .then(() => {
    console.log("Tokens saved");
    process.exit(0);
  })
  .catch((e) => {
    console.error("Error fetching tokens", e);
    process.exit(1);
  });
