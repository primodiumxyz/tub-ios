// Run with `pnpm tsx src/timescale/scripts/_poc.ts` to see the performance

import pg from "pg";

const LOCAL_URL = "postgres://tsdbadmin:password@localhost:5433/indexer";
const BATCH_SIZE = 100;
const INSERT_INTERVAL = 50; // 0.05 second
const TOTAL_RUNTIME = 5 * 60 * 1000; // 5 minutes

interface PerformanceMetrics {
  batchNumber: number;
  startTime: number;
  endTime: number;
  latency: number;
  recordsInserted: number;
  timestamp: string;
}

async function getClient() {
  const client = new pg.Client({
    connectionString: LOCAL_URL,
    password: "password",
  });
  await client.connect();
  return client;
}

function generateTokenData(createdAt: string) {
  const tokenSymbols = ["SOL", "BONK", "WEN", "PYTH", "DUST"];
  const randomSymbol = tokenSymbols[Math.floor(Math.random() * tokenSymbols.length)];

  return {
    token_mint: `${randomSymbol}_${Math.random().toString(36).substring(2, 15)}`,
    token_price_usd: (Math.random() * 100).toFixed(6),
    volume_usd: (Math.random() * 1000000).toFixed(2),
    created_at: createdAt,
    token_metadata: {
      name: `${randomSymbol} Token`,
      symbol: randomSymbol,
      description: `A test ${randomSymbol} token`,
      image_uri: `https://example.com/${randomSymbol?.toLowerCase()}.png`,
      external_url: `https://example.com/${randomSymbol?.toLowerCase()}`,
      supply: Math.floor(Math.random() * 1000000000),
      is_pump_token: Math.random() > 0.5,
    },
  };
}

async function verifyBatchInsertion(client: pg.Client, createdAt: string, expectedCount: number): Promise<boolean> {
  const query = `
    SELECT COUNT(*) as count
    FROM api.trade_history
    WHERE created_at = $1
  `;

  const result = await client.query(query, [createdAt]);
  const actualCount = parseInt(result.rows[0].count);

  if (actualCount !== expectedCount) {
    console.error(`Verification failed: expected ${expectedCount} records, found ${actualCount}`);
    return false;
  }
  return true;
}

async function insertBatchWithMetrics(
  client: pg.Client,
  trades: ReturnType<typeof generateTokenData>[],
  batchNumber: number,
): Promise<PerformanceMetrics> {
  const startTime = Date.now();
  const createdAt = new Date(startTime).toISOString();

  const tradesWithTimestamp = trades.map((trade) => ({
    ...trade,
    created_at: createdAt,
  }));

  const query = `
    SELECT api.batch_insert_trades($1::jsonb);
  `;

  await client.query(query, [JSON.stringify(tradesWithTimestamp)]);

  const verified = await verifyBatchInsertion(client, createdAt, trades.length);
  if (verified) {
    console.log(`Batch #${batchNumber} correctly inserted`);
  } else {
    throw new Error(`Failed to verify batch insertion at ${createdAt}`);
  }

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
  const client = await getClient();
  console.log("Connected to TimescaleDB");

  const metrics: PerformanceMetrics[] = [];
  let batchNumber = 0;
  const startTime = Date.now();

  try {
    while (Date.now() - startTime < TOTAL_RUNTIME) {
      // Generate batch of random trades
      const trades = Array.from({ length: BATCH_SIZE }, () => generateTokenData(new Date(Date.now()).toISOString()));

      // Insert batch and collect metrics
      const batchMetrics = await insertBatchWithMetrics(client, trades, ++batchNumber);

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
  } finally {
    await client.end();
  }
}

main().catch(console.error);
