import { afterAll, beforeAll, describe, it } from "vitest";
import { BenchmarkMockEnvironment, getGlobalEnv, ITERATIONS } from "./setup";
import { benchmark, BenchmarkMetrics, logMetrics, writeMetricsToFile } from "../lib/benchmarks";

describe("GetTopTokensByVolume benchmarks", () => {
  let env: BenchmarkMockEnvironment;

  const metrics: BenchmarkMetrics[] = [];

  beforeAll(async () => {
    env = await getGlobalEnv();
  });

  it("should measure direct Hasura performance", async () => {
    const metric = await benchmark({
      identifier: "Direct Hasura hit",
      query: env.gqlNoCache.db.GetTopTokensByVolumeQuery,
      variables: {
        interval: "30m",
        recentInterval: "20s",
      },
      iterations: ITERATIONS,
      after: (data) => {
        if (data.token_stats_interval_comp.length === 0) throw new Error("No tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure warm cache performance", async () => {
    // Cache warmup
    await env.gqlCached.db.GetTopTokensByVolumeQuery({
      interval: "30m",
      recentInterval: "20s",
    });

    const metric = await benchmark({
      identifier: "Warm cache hit",
      query: env.gqlCached.db.GetTopTokensByVolumeQuery,
      variables: {
        interval: "30m",
        recentInterval: "20s",
      },
      iterations: ITERATIONS,
      after: (data) => {
        if (data.token_stats_interval_comp.length === 0) throw new Error("No tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  afterAll(() => {
    logMetrics(metrics);
    writeMetricsToFile(metrics, "GetTopTokensByVolume");
  });
});
