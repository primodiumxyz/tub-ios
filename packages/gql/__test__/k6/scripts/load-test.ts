import http from "k6/http";
import { check, sleep } from "k6";
import { Gauge } from "k6/metrics";
import { SharedArray } from "k6/data";
import { Rate, Trend } from "k6/metrics";

const STRESS_STAGES = [
  { duration: "30s", target: 1000 }, // Ramp up to 1,000 users over 30 seconds
  { duration: "1m", target: 1000 }, // Stay at 1,000 users
  { duration: "30s", target: 0 }, // Ramp down to 0 users over 30 seconds
];

// Thresholds for stress testing
const STRESS_THRESHOLDS = {
  http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
  errors: ["rate<0.1"], // Error rate must be less than 10%
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

// Hasura metrics
const pgMemoryUsage = new Gauge("postgres_memory_usage");
const pgCPUUsage = new Gauge("postgres_cpu_usage");
const pgNetworkReceive = new Gauge("postgres_network_receive");
const pgNetworkTransmit = new Gauge("postgres_network_transmit");

// TimescaleDB metrics
const tsCacheHitRatio = new Gauge("timescale_cache_hit_ratio");
const tsMemoryUsage = new Gauge("timescale_memory_usage");
const tsCPUUsage = new Gauge("timescale_cpu_usage");
const tsNetworkReceive = new Gauge("timescale_network_receive");
const tsNetworkTransmit = new Gauge("timescale_network_transmit");

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
  try {
    const response = http.get(`http://localhost:9090/api/v1/query?query=${encodeURIComponent(query)}`, {
      headers: { "Content-Type": "application/json" },
    });

    const responseBody = response.json();

    if (response.status === 200) {
      const result = responseBody as {
        status?: string;
        data?: {
          resultType?: string;
          result?: Array<{
            metric?: Record<string, string>;
            value?: [number, string];
          }>;
        };
      };

      if (result.status === "success" && result.data?.result?.[0]?.value) {
        const value = parseFloat(result.data.result[0].value[1]);
        return value;
      } else {
        return 0;
      }
    }

    return 0;
  } catch (error) {
    if (error instanceof Error) {
      console.log("Error message:", error.message);
      console.log("Error stack:", error.stack);
    } else {
      console.log("Error in getPrometheusMetric:", error);
    }
    return 0;
  }
}

export default function () {
  try {
    const startTime = new Date().getTime();
    const headers = {
      "Content-Type": "application/json",
      "x-hasura-admin-secret": __ENV.HASURA_ADMIN_SECRET ?? "password",
    };

    // Run GraphQL query first
    const queryType = Math.random() > 0.5 ? "topTokens" : "tokenPrices";
    const payload = {
      query: QUERIES[queryType],
      variables:
        queryType === "tokenPrices"
          ? {
              token: tokens[Math.floor(Math.random() * tokens.length)],
              since: new Date(Date.now() - 30 * 1000).toISOString(),
            }
          : undefined,
    };

    const response = http.post(
      __ENV.HASURA_URL ? `${__ENV.HASURA_URL}/v1/graphql` : "http://localhost:8090/v1/graphql",
      JSON.stringify(payload),
      {
        headers,
      },
    );

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

    // PostgreSQL (Hasura) metrics with correct job and instance labels
    const pgMemory = getPrometheusMetric('process_resident_memory_bytes{job="postgres"}');
    const pgCPU = getPrometheusMetric('rate(process_cpu_seconds_total{job="postgres"}[1m])');
    const pgNetwork = {
      receive: getPrometheusMetric('rate(pg_stat_database_tup_returned{datname="postgres",job="postgres"}[1m])'),
      transmit: getPrometheusMetric('rate(pg_stat_database_tup_fetched{datname="postgres",job="postgres"}[1m])'),
    };

    // TimescaleDB metrics with correct job and instance labels
    const tsMemory = getPrometheusMetric('process_resident_memory_bytes{job="timescaledb"}');
    const tsCPU = getPrometheusMetric('rate(process_cpu_seconds_total{job="timescaledb"}[1m])');
    const tsNetwork = {
      receive: getPrometheusMetric('rate(pg_stat_database_tup_returned{datname="indexer",job="timescaledb"}[1m])'),
      transmit: getPrometheusMetric('rate(pg_stat_database_tup_fetched{datname="indexer",job="timescaledb"}[1m])'),
    };

    // Cache metrics for TimescaleDB
    const tsHits = getPrometheusMetric('pg_stat_database_blks_hit{datname="indexer",job="timescaledb"}');
    const tsReads = getPrometheusMetric('pg_stat_database_blks_read{datname="indexer",job="timescaledb"}');

    // Update gauges
    pgMemoryUsage.add(pgMemory / (1024 * 1024)); // MB
    pgCPUUsage.add(pgCPU * 100); // Percentage
    pgNetworkReceive.add(pgNetwork.receive); // Tuples/s
    pgNetworkTransmit.add(pgNetwork.transmit); // Tuples/s

    tsMemoryUsage.add(tsMemory / (1024 * 1024)); // MB
    tsCPUUsage.add(tsCPU * 100); // Percentage
    tsNetworkReceive.add(tsNetwork.receive); // Tuples/s
    tsNetworkTransmit.add(tsNetwork.transmit); // Tuples/s

    // Cache hit ratio for TimescaleDB
    if (tsHits + tsReads > 0) {
      const ratio = (tsHits / (tsHits + tsReads)) * 100;
      tsCacheHitRatio.add(ratio);
    }

    sleep(1);
  } catch (error) {
    if (error instanceof Error) {
      console.log("Error details:", {
        message: error.message,
        stack: error.stack,
      });
    } else {
      console.error("Error in test:", error);
    }
  }
}
