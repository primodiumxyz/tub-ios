import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";
import { SharedArray } from "k6/data";

// Load test tokens
const tokens = new SharedArray("tokens", function () {
  return JSON.parse(open("../output/tokens.json"));
});

// Custom metrics
const errorRate = new Rate("errors");

export const options = {
  stages: [
    { duration: "30s", target: 10 }, // Ramp up
    { duration: "1m", target: 10 }, // Stay at 10 users
    { duration: "30s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
    errors: ["rate<0.1"], // Error rate must be less than 10%
  },
};

const QUERIES = {
  topTokens: `
    query GetTopTokensByVolume($interval: interval = "30m", $recentInterval: interval = "20s") {
      token_stats_interval_comp(
        args: { interval: $interval, recent_interval: $recentInterval }
        where: { token_metadata_is_pump_token: { _eq: true } }
        order_by: { total_volume_usd: desc }
        limit: 50
      ) {
        token_mint
        total_volume_usd
        total_trades
      }
    }
  `,
  tokenPrices: `
    query GetTokenPricesSince($token: String!, $since: timestamptz!) {
      api_trade_history(
        where: { token_mint: { _eq: $token }, created_at: { _gte: $since } }
        order_by: { created_at: asc }
      ) {
        token_price_usd
        created_at
      }
    }
  `,
};

export default function () {
  const headers = {
    "Content-Type": "application/json",
    "x-hasura-admin-secret": __ENV.HASURA_ADMIN_SECRET ?? "password",
  };

  // Randomly select between queries
  const queryType = Math.random() > 0.5 ? "topTokens" : "tokenPrices";

  const payload = {
    query: QUERIES[queryType],
    variables:
      queryType === "tokenPrices"
        ? {
            token: tokens[Math.floor(Math.random() * tokens.length)],
            since: new Date(Date.now() - 30 * 60 * 1000).toISOString(), // Last 30 minutes
          }
        : {
            interval: "30m",
            recentInterval: "20s",
          },
  };

  const response = http.post(__ENV.HASURA_URL ?? "http://localhost:8090/v1/graphql", JSON.stringify(payload), {
    headers,
  });

  // Check if request was successful
  const success = check(response, {
    "is status 200": (r) => r.status === 200,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    "no errors": (r) => !(r.json() as any).errors,
  });

  if (!success) {
    errorRate.add(1);
  }

  sleep(1);
}
