import { GqlClient } from "../../src";
import { OperationContext } from "@urql/core";
import fs from "fs";
type BeforeHook = () => Promise<void>;

// Get all possible query functions from GqlClient
type QueryFn = GqlClient["db"][keyof GqlClient["db"]];

// Helper to get the actual data type from the operation result
type QueryData<T extends QueryFn> = NonNullable<Awaited<ReturnType<T>>["data"]>;

interface PerformanceTestOptions<T extends QueryFn> {
  identifier: string;
  query: T;
  variables: Parameters<T>[0];
  iterations: number;
  before?: BeforeHook;
  after?: (data: QueryData<T>) => void | Promise<void>;
  options?: Partial<OperationContext>;
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

export const benchmark = async <T extends QueryFn>({
  identifier,
  query,
  variables,
  iterations,
  before,
  after,
  options: contextOptions,
}: PerformanceTestOptions<T>): Promise<Omit<BenchmarkMetrics, "group">> => {
  const latencyMeasurements: number[] = [];

  for (let i = 0; i < iterations; i++) {
    if (before) await before();

    const start = performance.now();
    // @ts-expect-error type misunderstanding that doesn't impact usage
    const result = await query(variables, contextOptions);
    latencyMeasurements.push(performance.now() - start);

    if (after && result.data) {
      const afterResult = after(result.data);
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

  // Write raw CSV data for each group
  for (const group in groupedMetrics) {
    const csvContent = [
      // Header
      "name,avg,p95,min,max,stdDev",
      // Data rows
      ...groupedMetrics[group].map(
        (metric) => `${metric.name},${metric.avg},${metric.p95},${metric.min},${metric.max},${metric.stdDev}`,
      ),
    ].join("\n");

    // Ensure directory exists
    fs.mkdirSync("__test__/benchmarks/output", { recursive: true });

    // Write files for this group
    fs.writeFileSync(`__test__/benchmarks/output/${filename}_${group}.csv`, csvContent);
    fs.writeFileSync(`__test__/benchmarks/output/${filename}_${group}.txt`, formatMetricsReport(groupedMetrics[group]));
  }
};
