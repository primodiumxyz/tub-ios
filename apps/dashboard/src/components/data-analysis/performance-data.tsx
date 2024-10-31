// import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useMemo } from "react";

import { PerformanceChart } from "@/components/data-analysis/performance-data-chart";
import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useDataAnalysisData } from "@/hooks/use-data-analysis";
import { AFTER_INTERVALS } from "@/lib/constants";
import { TokenStats } from "@/lib/types";
import { getTokensPerformanceStats } from "@/lib/utils";

// Total average performance after the period has ended
// Average performance per interval during the period, using the same chart as the analytics
export const PerformanceBasePeriodDataTable = ({ chartWidth }: { chartWidth: number }) => {
  const { data, error, loading } = useDataAnalysisData();
  // const { from, to } = useAnalyticsParams();
  const stats = useMemo(() => (data ? getTokensPerformanceStats(data) : undefined), [data]);
  console.log(stats);

  const chartData = useMemo(() => {
    if (!stats) return [];

    return Array.from(stats.byInterval.entries())
      .map(([intervalStart, stats]) => ({
        interval_start: new Date(intervalStart),
        stats: stats.byAfterInterval,
      }))
      .sort((a, b) => a.interval_start.getTime() - b.interval_start.getTime());
  }, [stats]);

  if (loading && !stats) return <div className="w-full text-sm text-muted-foreground">This might take a while...</div>;
  if (error) return <div className="w-full text-sm text-muted-foreground">{error}</div>;
  if (!stats) return <div>No data</div>;

  return (
    <div className="w-full flex flex-col gap-8 items-start">
      <GlobalStatsTable stats={stats.global} />
      <PerformanceChart data={chartData} width={chartWidth} height={400} />
    </div>
  );
};

export const GlobalStatsTable = ({ stats }: { stats: TokenStats }) => {
  return (
    <Table className="text-start">
      <TableCaption>Global performance across {stats.tokenCount.toLocaleString()} tokens</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead>Interval after pump</TableHead>
          <TableHead>Avg. increase %</TableHead>
          <TableHead>Min increase %</TableHead>
          <TableHead>Max increase %</TableHead>
          <TableHead>Avg. trades</TableHead>
          <TableHead>Min trades</TableHead>
          <TableHead>Max trades</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {stats.byAfterInterval.map((interval, index) => (
          <TableRow key={index}>
            <TableCell className="font-medium">{AFTER_INTERVALS[index]}</TableCell>
            <TableCell>{interval.increasePct.avg.toLocaleString()}%</TableCell>
            <TableCell>{interval.increasePct.min.toLocaleString()}%</TableCell>
            <TableCell>{interval.increasePct.max.toLocaleString()}%</TableCell>
            <TableCell>{interval.trades.avg.toLocaleString()}</TableCell>
            <TableCell>{interval.trades.min.toLocaleString()}</TableCell>
            <TableCell>{interval.trades.max.toLocaleString()}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
};
