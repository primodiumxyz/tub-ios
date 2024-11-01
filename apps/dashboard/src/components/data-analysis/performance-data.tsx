import { useMemo, useState } from "react";

import { PerformanceChart } from "@/components/data-analysis/performance-data-chart";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useDataAnalysisData } from "@/hooks/use-data-analysis";
import { AFTER_INTERVALS, DEFAULT_SORT_BY, SortByMetric } from "@/lib/constants";
import { TokenStats } from "@/lib/types";
import { getTokensPerformanceStats } from "@/lib/utils";

export const PerformanceBasePeriodDataTable = ({ chartWidth }: { chartWidth: number }) => {
  const { data, error, loading } = useDataAnalysisData();
  const [sortBy, setSortBy] = useState<SortByMetric>(DEFAULT_SORT_BY);

  const stats = useMemo(() => (data ? getTokensPerformanceStats(data, sortBy) : undefined), [data, sortBy]);

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
      <div className="flex gap-2 items-center">
        <span className="text-sm text-muted-foreground">Sort by:</span>
        <Button
          variant={sortBy === SortByMetric.TRADES ? "secondary" : "ghost"}
          size="sm"
          onClick={() => setSortBy(SortByMetric.TRADES)}
        >
          Trades
        </Button>
        <Button
          variant={sortBy === SortByMetric.VOLUME ? "secondary" : "ghost"}
          size="sm"
          onClick={() => setSortBy(SortByMetric.VOLUME)}
        >
          Volume
        </Button>
      </div>
      <GlobalStatsTable stats={stats.global} sortBy={sortBy} />
      <PerformanceChart data={chartData} width={chartWidth} height={400} />
    </div>
  );
};

export const GlobalStatsTable = ({ stats, sortBy }: { stats: TokenStats; sortBy: SortByMetric }) => {
  return (
    <Table className="text-start">
      <TableCaption>
        Performance of top 10 tokens by {sortBy.toLowerCase()} during the next intervals across{" "}
        {stats.tokenCount.toLocaleString()} tokens
      </TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead>Next</TableHead>
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
