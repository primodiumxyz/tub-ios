import http from "k6/http";
import { check, sleep } from "k6";
import { Gauge } from "k6/metrics";
import { SharedArray } from "k6/data";
import { Rate, Trend } from "k6/metrics";

// Stages for stress testing
const STRESS_STAGES = [
  { duration: "1s", target: 10 }, // Ramp up to 1,000 users over 30 seconds
  { duration: "3s", target: 10 }, // Stay at 1,000 users
  { duration: "1s", target: 0 }, // Ramp down to 0 users over 30 seconds
];

// Thresholds for stress testing
const STRESS_THRESHOLDS = {
  http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
  errors: ["rate<0.1"], // Error rate must be less than 10%
  postgres_cache_hit_ratio: ["value>0"],
  timescale_cache_hit_ratio: ["value>0"],
};

// Load test tokens
const tokens = new SharedArray("tokens", function () {
  return JSON.parse(open("../output/tokens.json"));
});

// Custom metrics
const errorRate = new Rate("errors");
const queryTopTokens = new Trend("query_top_tokens");
const queryTokenPrices = new Trend("query_token_prices");

// Register database metrics (using Gauge for all)
const pgCacheHitRatio = new Gauge("postgres_cache_hit_ratio");
const pgBufferHits = new Gauge("postgres_buffer_hits");
const pgDiskReads = new Gauge("postgres_disk_reads");
const tsCacheHitRatio = new Gauge("timescale_cache_hit_ratio");
const tsBufferHits = new Gauge("timescale_buffer_hits");
const tsDiskReads = new Gauge("timescale_disk_reads");

export const options = {
  stages: STRESS_STAGES,
  thresholds: STRESS_THRESHOLDS,
};

const QUERIES = {
  topTokens: `
    query GetTopTokensByVolume {
      token_rolling_stats_30min(
        where: { is_pump_token: { _eq: true } }
        order_by: { volume_usd_30m: desc }
        limit: 50
      ) {
        mint
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

function getPrometheusMetric(query: string): number {
  console.log(`Querying Prometheus: ${query}`);

  const response = http.post("http://localhost:9090/api/v1/query", JSON.stringify({ query }), {
    headers: { "Content-Type": "application/json" },
  });

  console.log(`Prometheus response status: ${response.status}`);
  console.log(`Prometheus response body: ${response.body}`);

  if (response.status === 200) {
    const result = response.json() as { data?: { result?: Array<{ value?: [number, string] }> } };
    const value = parseFloat(result?.data?.result?.[0]?.value?.[1] || "0");
    console.log(`Extracted value: ${value}`);
    return value;
  }

  console.log("Failed to get metric");
  return 0;
}

export default function () {
  try {
    const startTime = new Date().getTime();
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
              since: new Date(Date.now() - 30 * 1000).toISOString(), // Last 30 seconds
            }
          : undefined,
    };

    const response = http.post(__ENV.HASURA_URL ?? "http://localhost:8090/v1/graphql", JSON.stringify(payload), {
      headers,
    });

    const duration = new Date().getTime() - startTime;

    // Track query-specific metrics
    if (queryType === "topTokens") {
      queryTopTokens.add(duration);
    } else {
      queryTokenPrices.add(duration);
    }

    // Check if request was successful
    const success = check(response, {
      "is status 200": (r) => r.status === 200,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      "no errors": (r) => !(r.json() as any).errors,
    });

    if (!success) {
      errorRate.add(1);
    }

    // Collect DB metrics
    console.log("Collecting Postgres metrics...");
    const pgHits = getPrometheusMetric('pg_stat_database_blks_hit{datname="postgres"}');
    const pgReads = getPrometheusMetric('pg_stat_database_blks_read{datname="postgres"}');

    console.log("Collecting TimescaleDB metrics...");
    const tsHits = getPrometheusMetric('pg_stat_database_blks_hit{datname="indexer"}');
    const tsReads = getPrometheusMetric('pg_stat_database_blks_read{datname="indexer"}');

    console.log(`Postgres hits: ${pgHits}, reads: ${pgReads}`);
    console.log(`TimescaleDB hits: ${tsHits}, reads: ${tsReads}`);

    // Update Postgres metrics
    pgBufferHits.add(pgHits);
    pgDiskReads.add(pgReads);
    if (pgHits + pgReads > 0) {
      const ratio = (pgHits / (pgHits + pgReads)) * 100;
      console.log(`Postgres cache hit ratio: ${ratio}%`);
      pgCacheHitRatio.add(ratio);
    }

    // Update TimescaleDB metrics
    tsBufferHits.add(tsHits);
    tsDiskReads.add(tsReads);
    if (tsHits + tsReads > 0) {
      const ratio = (tsHits / (tsHits + tsReads)) * 100;
      console.log(`TimescaleDB cache hit ratio: ${ratio}%`);
      tsCacheHitRatio.add(ratio);
    }

    sleep(1);
  } catch (error) {
    console.error("Error in test:", error);
  }
}
