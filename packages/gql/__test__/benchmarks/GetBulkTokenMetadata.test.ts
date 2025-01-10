import { afterAll, beforeAll, describe, it } from "vitest";
import { BenchmarkMockEnvironment, getGlobalEnv, ITERATIONS } from "./setup";
import { benchmark, BenchmarkMetrics, logMetrics, writeMetricsToFile } from "../lib/benchmarks";
import { createClientCacheBypass, createClientCached, createClientNoCache } from "../lib/common";

describe("GetBulkTokenMetadata benchmarks", () => {
  let env: BenchmarkMockEnvironment;
  const tokenBatches: string[][] = [];
  const metrics: BenchmarkMetrics[] = [];

  beforeAll(async () => {
    env = await getGlobalEnv();
    // Create RANDOM batches of 20 tokens for each iteration
    for (let i = 0; i < ITERATIONS; i++) {
      tokenBatches.push(
        env
          .getTokenMints()
          .sort(() => Math.random() - 0.5)
          .slice(i * 20, (i + 1) * 20),
      );
    }
  });

  it("should measure direct Hasura performance", async () => {
    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Direct Hasura hit",
      exec: async (i) => {
        const client = await createClientNoCache();
        return await client.db.GetBulkTokenMetadataQuery({
          tokens: tokenBatches[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_metadata_formatted.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure warm cache performance", async () => {
    // Cache warmup
    for (let i = 0; i < ITERATIONS; i++) {
      await env.defaultClient.db.GetBulkTokenMetadataQuery({
        tokens: tokenBatches[i],
      });
    }

    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Warm cache hit",
      exec: async (i) => {
        const client = await createClientCached();

        return await client.db.GetBulkTokenMetadataQuery({
          tokens: tokenBatches[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_metadata_formatted.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure cold cache performance", async () => {
    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Cold cache hit",
      exec: async (i) => {
        const client = await createClientCached();

        return await client.db.GetBulkTokenMetadataQuery({
          tokens: tokenBatches[i],
        });
      },
      iterations: ITERATIONS,
      before: async () => await env.clearCache(),
      after: (res) => {
        if (res.error || res.data?.token_metadata_formatted.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  it("should measure bypassing cache performance", async () => {
    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Bypassing cache",
      exec: async (i) => {
        const client = await createClientCacheBypass();
        return await client.db.GetBulkTokenMetadataQuery({
          tokens: tokenBatches[i],
        });
      },
      iterations: ITERATIONS,
      after: (res) => {
        if (res.error || res.data?.token_metadata_formatted.length === 0) throw new Error("Error or no tokens found");
      },
    });

    metrics.push({ ...metric, group: "A" });
  });

  afterAll(() => {
    logMetrics(metrics);
    writeMetricsToFile(metrics, "GetBulkTokenMetadata");
  });
});
