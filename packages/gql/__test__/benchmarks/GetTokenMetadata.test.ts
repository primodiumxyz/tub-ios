import { afterAll, beforeAll, describe, it } from "vitest";
import { benchmark, BenchmarkMetrics, logMetrics, writeMetricsToFile } from "../lib/benchmarks";
import { clearCache, createClientCacheBypass, createClientCached, createClientNoCache } from "../lib/common";
import { ITERATIONS } from "./config";

describe("GetBulkTokenMetadata (single token) benchmarks", () => {
  let tokens: string[] = [];
  const metrics: BenchmarkMetrics[] = [];

  beforeAll(async () => {
    const client = await createClientNoCache();
    const res = await client.db.GetAllTokensQuery();
    if (res.error || !res.data?.token_metadata_formatted) throw new Error("No tokens found");
    tokens = res.data?.token_metadata_formatted.map((t) => t.mint) || [];
  });

  it("should measure direct Hasura performance", async () => {
    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Direct Hasura hit",
      exec: async (i) => {
        const client = await createClientNoCache();
        return await client.db.GetBulkTokenMetadataQuery({
          tokens: [tokens[i]],
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
      const client = await createClientCached();
      await client.db.GetBulkTokenMetadataQuery({
        tokens: [tokens[i]],
      });
    }

    const metric = await benchmark<"GetBulkTokenMetadataQuery">({
      identifier: "Warm cache hit",
      exec: async (i) => {
        const client = await createClientCached();

        return await client.db.GetBulkTokenMetadataQuery({
          tokens: [tokens[i]],
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
          tokens: [tokens[i]],
        });
      },
      iterations: ITERATIONS,
      before: async () => await clearCache(),
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
          tokens: [tokens[i]],
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
    writeMetricsToFile(metrics, "GetBulkTokenMetadata_single_token");
  });
});
