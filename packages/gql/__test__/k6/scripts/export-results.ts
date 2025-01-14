import fs from "fs";

const exportDashboardData = async () => {
  try {
    // Give InfluxDB time to process final data points
    await new Promise((resolve) => setTimeout(resolve, 2000));

    const queries = [
      'SELECT mean("value") FROM "http_req_duration" WHERE time > now() - 5m GROUP BY time(10s)',
      'SELECT mean("value") FROM "query_top_tokens" WHERE time > now() - 5m GROUP BY time(10s)',
      'SELECT mean("value") FROM "query_token_prices" WHERE time > now() - 5m GROUP BY time(10s)',
      'SELECT count("value") FROM "query_count" WHERE time > now() - 5m',
      'SELECT mean("value") FROM "errors" WHERE time > now() - 5m',
    ].join(";");

    // Query InfluxDB directly for the data
    const response = await fetch(
      "http://localhost:8086/query?" +
        new URLSearchParams({
          db: "k6",
          epoch: "ms",
          q: queries,
        }),
      {
        method: "GET",
        headers: {
          Accept: "application/json",
          Authorization: "Basic " + Buffer.from("admin:admin").toString("base64"),
        },
      },
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    console.log("Raw InfluxDB response:", data); // Debug log

    const outputDir = "./__test__/k6/output/metrics";
    fs.mkdirSync(outputDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

    // Save raw dashboard data
    fs.writeFileSync(`${outputDir}/metrics_${timestamp}.json`, JSON.stringify(data, null, 2));

    // Process and save metrics summary
    const summary = processMetrics(data);
    fs.writeFileSync(`${outputDir}/metrics_summary_${timestamp}.txt`, formatSummary(summary));

    console.log("Dashboard data exported successfully");
  } catch (error) {
    console.error("Failed to export dashboard data:", error);
  }
};

interface MetricsSummary {
  overall: {
    avg: number;
    min: number;
    max: number;
    p95: number;
  };
  byQuery: {
    topTokens: { avg: number; count: number };
    tokenPrices: { avg: number; count: number };
  };
  timestamp: string;
  totalDuration: string;
  totalRequests: number;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const processMetrics = (data: any): MetricsSummary => {
  // InfluxDB returns an array of results for each query
  const [httpDuration, topTokens, tokenPrices] = data.results;

  // Process overall HTTP duration metrics
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const durationValues = httpDuration.series?.[0]?.values?.map((v: any[]) => v[1]) ?? [];
  const sortedDurations = durationValues.filter(Boolean).sort((a: number, b: number) => a - b);

  const overall = {
    avg: durationValues.reduce((a: number, b: number) => a + b, 0) / durationValues.length,
    min: sortedDurations[0] ?? 0,
    max: sortedDurations[sortedDurations.length - 1] ?? 0,
    p95: sortedDurations[Math.floor(sortedDurations.length * 0.95)] ?? 0,
  };

  // Process query-specific metrics
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const topTokensValues = topTokens.series?.[0]?.values?.map((v: any[]) => v[1]) ?? [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const tokenPricesValues = tokenPrices.series?.[0]?.values?.map((v: any[]) => v[1]) ?? [];

  const byQuery = {
    topTokens: {
      avg: topTokensValues.reduce((a: number, b: number) => a + b, 0) / topTokensValues.length || 0,
      count: topTokensValues.filter(Boolean).length,
    },
    tokenPrices: {
      avg: tokenPricesValues.reduce((a: number, b: number) => a + b, 0) / tokenPricesValues.length || 0,
      count: tokenPricesValues.filter(Boolean).length,
    },
  };

  return {
    overall,
    byQuery,
    timestamp: new Date().toISOString(),
    totalDuration: `${Math.round((durationValues.length * 10) / 60)} minutes`, // Since we grouped by 10s
    totalRequests: byQuery.topTokens.count + byQuery.tokenPrices.count,
  };
};

const formatSummary = (summary: MetricsSummary): string => {
  return `
🚀 Load Test Dashboard Summary

Overall Performance:
• Average Response Time: ${summary.overall.avg.toFixed(2)}ms
• P95 Response Time: ${summary.overall.p95.toFixed(2)}ms
• Min Response Time: ${summary.overall.min.toFixed(2)}ms
• Max Response Time: ${summary.overall.max.toFixed(2)}ms

Query Performance:
• TopTokens: ${summary.byQuery.topTokens.avg.toFixed(2)}ms avg (${summary.byQuery.topTokens.count} requests)
• TokenPrices: ${summary.byQuery.tokenPrices.avg.toFixed(2)}ms avg (${summary.byQuery.tokenPrices.count} requests)
`;
};

exportDashboardData()
  .then(() => {
    console.log("Dashboard data exported successfully");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Failed to export dashboard data:", error);
    process.exit(1);
  });
