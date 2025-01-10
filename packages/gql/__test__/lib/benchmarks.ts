import { GqlClient } from "../../src";
import fs from "fs";
type BeforeHook = () => Promise<void>;

// Get all possible query functions from GqlClient
export type QueryFnName = keyof GqlClient["db"];

// Helper to get the result from the operation
type QueryResult<T extends QueryFnName> = Awaited<ReturnType<GqlClient["db"][T]>>;

export interface PerformanceTestOptions<T extends QueryFnName> {
  identifier: string;
  exec: (i: number) => Promise<QueryResult<T>>;
  iterations: number;
  before?: BeforeHook;
  after?: (result: QueryResult<T>) => void | Promise<void>;
}

export interface BenchmarkMetrics {
  name: string;
  group: string;
  avg: number;
  min: number;
  max: number;
  p95: number;
  stdDev: number;
}

/* -------------------------------------------------------------------------- */
/*                                BENCHMARKING                                */
/* -------------------------------------------------------------------------- */

export const benchmark = async <T extends QueryFnName>({
  identifier,
  // We cannot pass the query function here directly, because we need to perform each query _with a separate client_
  // Otherwise, it will consider all similar queries in the same test to be the same query, no matter how much we try to separate them, and cache them together
  exec,
  iterations,
  before,
  after,
}: PerformanceTestOptions<T>): Promise<Omit<BenchmarkMetrics, "group">> => {
  const latencyMeasurements: number[] = [];

  for (let i = 0; i < iterations; i++) {
    if (before) await before();

    const start = performance.now();
    const result = await exec(i);
    latencyMeasurements.push(performance.now() - start);

    if (after && result) {
      const afterResult = after(result);
      if (afterResult instanceof Promise) await afterResult;
    }
  }

  return {
    name: identifier,
    ...calculateStats(latencyMeasurements),
  };
};

const calculateStats = (measurements: number[]): Omit<BenchmarkMetrics, "name" | "group"> => {
  return {
    avg: average(measurements),
    min: Math.min(...measurements),
    max: Math.max(...measurements),
    p95: percentile(measurements, 95),
    stdDev: standardDeviation(measurements),
  };
};

const average = (measurements: number[]) => {
  return measurements.reduce((sum, measurement) => sum + measurement, 0) / measurements.length;
};

const percentile = (measurements: number[], p: number) => {
  const sorted = measurements.sort((a, b) => a - b);
  const index = (p / 100) * (sorted.length - 1);
  return sorted[Math.round(index)];
};

const standardDeviation = (measurements: number[]) => {
  const avg = average(measurements);
  const variance =
    measurements.reduce((sum, measurement) => sum + Math.pow(measurement - avg, 2), 0) / measurements.length;
  return Math.sqrt(variance);
};

/* -------------------------------------------------------------------------- */
/*                                    LOGS                                    */
/* -------------------------------------------------------------------------- */

const formatMetricsReport = (metrics: BenchmarkMetrics[]): string => {
  const lines: string[] = [];
  const sortedMetrics = [...metrics].sort((a, b) => a.avg - b.avg);
  const fastest = sortedMetrics[0];

  lines.push("\n📊 Performance Comparison:");
  lines.push("=".repeat(80));
  lines.push("");

  // Individual metrics
  sortedMetrics.forEach((metric) => {
    lines.push(`🔍 ${metric.name}`);
    lines.push("-".repeat(40));
    lines.push(`Average Response Time: ${metric.avg.toFixed(2)}ms`);
    lines.push(`95th Percentile:       ${metric.p95.toFixed(2)}ms`);
    lines.push(`Min Response Time:     ${metric.min.toFixed(2)}ms`);
    lines.push(`Max Response Time:     ${metric.max.toFixed(2)}ms`);
    lines.push(`Standard Deviation:    ${metric.stdDev.toFixed(2)}ms`);
    lines.push("");
  });

  // Add detailed comparisons if we have multiple metrics
  if (metrics.length >= 2) {
    lines.push("⚡ Performance Impact:");
    lines.push("-".repeat(80));
    lines.push(`Best performer: ${fastest.name}`);
    lines.push("");

    sortedMetrics.slice(1).forEach((slower) => {
      lines.push(`Compared to ${slower.name}:`);
      lines.push("-".repeat(80));
      lines.push("Metric               │ Difference     │ Percentage");
      lines.push("-".repeat(80));

      const comparisons = [
        { name: "Average Response", base: fastest.avg, compare: slower.avg },
        { name: "95th Percentile", base: fastest.p95, compare: slower.p95 },
        { name: "Min Response", base: fastest.min, compare: slower.min },
        { name: "Max Response", base: fastest.max, compare: slower.max },
        { name: "Standard Deviation", base: fastest.stdDev, compare: slower.stdDev },
      ];

      comparisons.forEach(({ name, base, compare }) => {
        const diff = compare - base;
        const percentage = ((diff / base) * 100).toFixed(1);
        lines.push(`${name.padEnd(20)}│ +${diff.toFixed(2).padEnd(12)}│ +${percentage.padEnd(8)}%`);
      });
      lines.push("");
    });
  }

  lines.push("");
  return lines.join("\n");
};

export const logMetrics = (metrics: BenchmarkMetrics[]) => {
  const groupedMetrics = metrics.reduce((acc, metric) => {
    acc[metric.group] = [...(acc[metric.group] || []), metric];
    return acc;
  }, {});

  for (const group in groupedMetrics) {
    console.log(formatMetricsReport(groupedMetrics[group]));
  }
};

export const writeMetricsToFile = (metrics: BenchmarkMetrics[], filename: string) => {
  // Group metrics
  const groupedMetrics = metrics.reduce(
    (acc, metric) => {
      acc[metric.group] = [...(acc[metric.group] || []), metric];
      return acc;
    },
    {} as Record<string, BenchmarkMetrics[]>,
  );

  // Write JSON data for each group
  for (const group in groupedMetrics) {
    // Ensure directory exists
    fs.mkdirSync("__test__/benchmarks/output", { recursive: true });

    // Write files for this group
    fs.writeFileSync(
      `__test__/benchmarks/output/${filename}_${group}.json`,
      JSON.stringify(groupedMetrics[group], null, 2),
    );
    fs.writeFileSync(`__test__/benchmarks/output/${filename}_${group}.txt`, formatMetricsReport(groupedMetrics[group]));

    // Print the summary
    analyzeBenchmarks();
  }
};

interface QuerySummary {
  queryName: string;
  directHasura: number;
  warmCache: number;
  coldCache: number;
  bypassCache: number;
  improvement: number;
}

const analyzeBenchmarks = () => {
  const outputDir = "__test__/benchmarks/output";
  const jsonFiles = fs.readdirSync(outputDir).filter((f) => f.startsWith("Get") && f.endsWith(".json"));
  const summaries: QuerySummary[] = [];

  // Parse JSON files
  for (const file of jsonFiles) {
    const queryName = file.replace(/_[A-Z]\.json$/, "");
    const content = fs.readFileSync(`${outputDir}/${file}`, "utf-8");
    const results = JSON.parse(content);

    const summary: QuerySummary = {
      queryName,
      directHasura: results.find((r) => r.name === "Direct Hasura hit")?.avg || 0,
      warmCache: results.find((r) => r.name === "Warm cache hit")?.avg || 0,
      coldCache: results.find((r) => r.name === "Cold cache hit")?.avg || 0,
      bypassCache: results.find((r) => r.name === "Bypassing cache")?.avg || 0,
      improvement: 0,
    };

    summary.improvement = ((summary.directHasura - summary.warmCache) / summary.directHasura) * 100;
    summaries.push(summary);
  }

  // Generate report
  const format = (num: number) => num.toFixed(2).padStart(8, " ");
  const lines: string[] = [
    "\n🚀 Query Performance Overview\n",
    "│ Query Name │ Direct │ Warm Cache │ Cold Cache │ Bypass Cache │ Improvement │",
    "│───────────│────────│────────────│────────────│──────────────│─────────────│",
  ];

  summaries.forEach((s) => {
    lines.push(
      `│ ${s.queryName.padEnd(9)} │` +
        `${format(s.directHasura)}ms │` +
        `${format(s.warmCache)}ms │` +
        `${format(s.coldCache)}ms │` +
        `${format(s.bypassCache)}ms │` +
        `${format(s.improvement)}% │`,
    );
  });

  // Add insights
  const fastestQuery = summaries.reduce((a, b) => (a.warmCache < b.warmCache ? a : b));
  const slowestQuery = summaries.reduce((a, b) => (a.directHasura > b.directHasura ? a : b));
  const bestImprovement = summaries.reduce((a, b) => (a.improvement > b.improvement ? a : b));

  lines.push(
    "\n📊 Key Insights:",
    `• Fastest query (warm cache): ${fastestQuery.queryName} (${fastestQuery.warmCache.toFixed(2)}ms)`,
    `• Slowest query (direct): ${slowestQuery.queryName} (${slowestQuery.directHasura.toFixed(2)}ms)`,
    `• Best cache improvement: ${bestImprovement.queryName} (${bestImprovement.improvement.toFixed(2)}%)`,
  );

  // Output report
  const report = lines.join("\n");
  console.log(report);
  fs.writeFileSync(`${outputDir}/summary.txt`, report);
  fs.writeFileSync(`${outputDir}/summary.json`, JSON.stringify(summaries, null, 2));
};
