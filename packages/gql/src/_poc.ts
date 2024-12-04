// Run with `pnpm tsx src/_poc.ts` to see the performance
import { createClient, GqlClient } from "@tub/gql";

const BATCH_SIZE = 100;
const INSERT_INTERVAL = 50; // 0.05 second
const TOTAL_RUNTIME = 5 * 60 * 1000; // 5 minutes

interface PerformanceMetrics {
  batchNumber: number;
  startTime: number;
  endTime: number;
  latency: number;
  recordsInserted: number;
  timestamp: Date;
}

function generateTokenData(createdAt: string) {
  const tokenSymbols = ["SOL", "BONK", "WEN", "PYTH", "DUST"];
  const randomSymbol = tokenSymbols[Math.floor(Math.random() * tokenSymbols.length)];

  return {
    token_mint: `${randomSymbol}_${Math.random().toString(36).substring(2, 15)}`,
    token_price_usd: (Math.random() * 100).toFixed(6),
    volume_usd: (Math.random() * 1000000).toFixed(2),
    created_at: createdAt,
    token_metadata: toPgComposite({
      name: `${randomSymbol} Token`,
      symbol: randomSymbol,
      description: `A test ${randomSymbol} token`,
      image_uri: `https://example.com/${randomSymbol?.toLowerCase()}.png`,
      external_url: `https://example.com/${randomSymbol?.toLowerCase()}`,
      supply: Math.floor(Math.random() * 1000000000),
      is_pump_token: Math.random() > 0.5,
    }),
  };
}

function printMetrics(metrics: PerformanceMetrics) {
  console.log(`Batch #${metrics.batchNumber}`);
  console.log(`Timestamp: ${metrics.timestamp}`);
  console.log(`Latency: ${metrics.latency}ms`);
  console.log(`Records: ${metrics.recordsInserted}`);
  console.log(`Insertion Rate: ${(metrics.recordsInserted / (metrics.latency / 1000)).toFixed(2)} records/second`);
  console.log("-------------------");
}

function calculateAggregateMetrics(allMetrics: PerformanceMetrics[]) {
  const totalRecords = allMetrics.reduce((sum, m) => sum + m.recordsInserted, 0);
  const totalTime = (allMetrics[allMetrics.length - 1]?.endTime ?? 0) - (allMetrics[0]?.startTime ?? 0);
  const avgLatency = allMetrics.reduce((sum, m) => sum + m.latency, 0) / allMetrics.length;
  const maxLatency = Math.max(...allMetrics.map((m) => m.latency));

  console.log("\nAggregate Metrics:");
  console.log(`Total Runtime: ${(totalTime / 1000).toFixed(2)} seconds`);
  console.log(`Total Records: ${totalRecords}`);
  console.log(`Average Latency: ${avgLatency.toFixed(2)}ms`);
  console.log(`Max Latency: ${maxLatency}ms`);
  console.log(`Overall Insertion Rate: ${(totalRecords / (totalTime / 1000)).toFixed(2)} records/second`);
}

async function main() {
  // Initialize the GraphQL client
  const gqlClient = (
    await createClient({
      url: "http://localhost:8080/v1/graphql",
      hasuraAdminSecret: "password",
    })
  ).db;

  const metrics: PerformanceMetrics[] = [];
  let batchNumber = 0;
  const startTime = Date.now();

  try {
    while (Date.now() - startTime < TOTAL_RUNTIME) {
      // Generate batch of random trades
      const trades = Array.from({ length: BATCH_SIZE }, () => generateTokenData(new Date(Date.now()).toISOString()));

      // Insert batch and collect metrics
      const batchMetrics = await insertBatchWithMetrics(gqlClient, trades, ++batchNumber);

      metrics.push(batchMetrics);
      printMetrics(batchMetrics);

      // Check if we're falling behind
      const actualInterval = Date.now() - batchMetrics.startTime;
      if (actualInterval > INSERT_INTERVAL) {
        console.warn(`⚠️ Warning: Falling behind by ${actualInterval - INSERT_INTERVAL}ms`);
      }

      // Wait for next interval
      await new Promise((resolve) => setTimeout(resolve, Math.max(0, INSERT_INTERVAL - batchMetrics.latency)));
    }

    // Print final statistics
    calculateAggregateMetrics(metrics);
  } catch (error) {
    console.error("Error:", error);
  }
}

export const toPgComposite = (obj: Record<string, unknown>): string => {
  const values = Object.values(obj).map((val) => {
    if (val === null || val === undefined) return null;
    // Escape quotes by doubling them (PostgreSQL syntax)
    if (typeof val === "string") return `"${val.replace(/"/g, '""')}"`;
    if (typeof val === "number") return isNaN(val) ? null : val.toString();
    // For any other value that might be numeric (like BigInt) or string
    return val.toString();
  });

  return `(${values.join(",")})`;
};

async function insertBatchWithMetrics(
  gqlClient: GqlClient["db"],
  trades: ReturnType<typeof generateTokenData>[],
  batchNumber: number,
): Promise<PerformanceMetrics> {
  const startTime = Date.now();
  const createdAt = new Date(startTime);

  // Use GraphQL mutation instead of SQL query
  const result = await gqlClient.InsertTradeHistoryManyMutation({
    trades: trades.map((trade) => ({
      ...trade,
      created_at: createdAt,
    })),
  });

  if (result.error) {
    throw new Error(`Failed to insert batch: ${result.error.message}`);
  }

  console.log(`Batch #${batchNumber} correctly inserted`);

  const endTime = Date.now();
  const latency = endTime - startTime;

  return {
    batchNumber,
    startTime,
    endTime,
    latency,
    recordsInserted: trades.length,
    timestamp: createdAt,
  };
}

main().catch(console.error);
