import { afterAll, beforeAll, describe, it } from "vitest";
import { BenchmarkMockEnvironment, getGlobalEnv, ITERATIONS } from "./setup";
import { benchmark, BenchmarkMetrics, logMetrics, writeMetricsToFile } from "../lib/benchmarks";
import { createClientCacheBypass, createClientCached, createClientNoCache } from "../lib/common";

describe("GetTokenLiveData benchmarks", () => {
  let env: BenchmarkMockEnvironment;
  let tokens: string[] = [];
  const metrics: BenchmarkMetrics[] = [];

  beforeAll(async () => {
    env = await getGlobalEnv();
    tokens = env.getTokenMints().slice(0, ITERATIONS);
  });

  it("should measure direct Hasura performance", async () => {
    const metric = await benchmark<"GetTokenLiveDataQuery">({
      identifier: "Direct Hasura hit",
      exec: async (i) => {
        const client = await createClientNoCache();
        return await client.db.GetTokenLiveDataQuery({
          token: tokens[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_comp.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure warm cache performance", async () => {
    // Cache warmup
    for (let i = 0; i < ITERATIONS; i++) {
      await env.defaultClient.db.GetTokenLiveDataQuery({
        token: tokens[i],
      });
    }

    const metric = await benchmark<"GetTokenLiveDataQuery">({
      identifier: "Warm cache hit",
      exec: async (i) => {
        const client = await createClientCached();

        return await client.db.GetTokenLiveDataQuery({
          token: tokens[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_comp.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure cold cache performance", async () => {
    const metric = await benchmark<"GetTokenLiveDataQuery">({
      identifier: "Cold cache hit",
      exec: async (i) => {
        const client = await createClientCached();

        return await client.db.GetTokenLiveDataQuery({
          token: tokens[i],
        });
      },
      iterations: ITERATIONS,
      before: async () => await env.clearCache(),
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_comp.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure bypassing cache performance", async () => {
    const metric = await benchmark<"GetTokenLiveDataQuery">({
      identifier: "Bypassing cache",
      exec: async (i) => {
        const client = await createClientCacheBypass();
        return await client.db.GetTokenLiveDataQuery({
          token: tokens[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_stats_interval_comp.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  afterAll(() => {
    logMetrics(metrics);
    writeMetricsToFile(metrics, "GetTokenLiveData");
  });
});
