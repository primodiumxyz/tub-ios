import { afterAll, describe, it } from "vitest";
import { benchmark, BenchmarkMetrics, logMetrics, writeMetricsToFile } from "../lib/benchmarks";
import { clearCache, createClientCacheBypass, createClientCached, createClientNoCache } from "../lib/common";
import { ITERATIONS } from "./config";

describe("GetTopTokensByVolume (old) benchmarks", () => {
  const metrics: BenchmarkMetrics[] = [];

  it("should measure direct Hasura performance", async () => {
    const metric = await benchmark<"GetTopTokensByVolumeQuery_old">({
      identifier: "Direct Hasura hit",
      exec: async () => {
        const client = await createClientNoCache();
        return await client.db.GetTopTokensByVolumeQuery_old({
          interval: "30m",
          recentInterval: "1m",
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_cache.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure warm cache performance", async () => {
    // Cache warmup
    const client = await createClientCached();
    await client.db.GetTopTokensByVolumeQuery_old({
      interval: "30m",
      recentInterval: "1m",
    });

    const metric = await benchmark<"GetTopTokensByVolumeQuery_old">({
      identifier: "Warm cache hit",
      exec: async () => {
        const client = await createClientCached();

        return await client.db.GetTopTokensByVolumeQuery_old({
          interval: "30m",
          recentInterval: "1m",
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_cache.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure cold cache performance", async () => {
    const metric = await benchmark<"GetTopTokensByVolumeQuery_old">({
      identifier: "Cold cache hit",
      exec: async () => {
        const client = await createClientCached();

        return await client.db.GetTopTokensByVolumeQuery_old({
          interval: "30m",
          recentInterval: "1m",
        });
      },
      iterations: ITERATIONS,
      before: async () => await clearCache(),
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_cache.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure bypassing cache performance", async () => {
    const metric = await benchmark<"GetTopTokensByVolumeQuery_old">({
      identifier: "Bypassing cache",
      exec: async () => {
        const client = await createClientCacheBypass();
        return await client.db.GetTopTokensByVolumeQuery_old({
          interval: "30m",
          recentInterval: "1m",
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_cache.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  afterAll(() => {
    logMetrics(metrics);
    writeMetricsToFile(metrics, "GetTopTokensByVolume_old");
  });
});
