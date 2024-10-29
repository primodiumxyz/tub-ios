import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";

export const useDataAnalysisData = (): {
  data:
    | {
        mint: string;
        increase_pct: string;
        trades: string;
        increase_pct_after: string;
        trades_after: string;
        pump_duration: string;
        created_at: Date;
        interval_start: Date;
      }[]
    | undefined;
  error: string | undefined;
  loading: boolean;
  refetch: () => void;
} => {
  const { from, to } = useAnalyticsParams();
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const [filteredTokensPerformancePerInterval, queryFilteredTokensPerformancePerInterval] = useQuery({
    query: queries.GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery,
    variables: { from, to, interval: timespan, increasePct: increasePct.toString(), minTrades: minTrades.toString() },
    requestPolicy: "network-only",
  });

  return useMemo(
    () => ({
      data: filteredTokensPerformancePerInterval.data?.get_formatted_tokens_with_performance_intervals_within_period,
      error: filteredTokensPerformancePerInterval.error?.message,
      loading: filteredTokensPerformancePerInterval.fetching,
      refetch: queryFilteredTokensPerformancePerInterval,
    }),
    [
      filteredTokensPerformancePerInterval.data,
      filteredTokensPerformancePerInterval.error,
      filteredTokensPerformancePerInterval.fetching,
      queryFilteredTokensPerformancePerInterval,
    ],
  );
};
