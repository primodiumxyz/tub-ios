import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { AFTER_INTERVALS } from "@/lib/constants";

export const useDataAnalysisData = (): {
  data:
    | {
        mint: string;
        increase_pct: string;
        trades: string;
        increase_pct_after: number[];
        trades_after: number[];
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
    variables: {
      from,
      to,
      interval: timespan,
      afterIntervals: AFTER_INTERVALS.join(","),
      increasePct: increasePct.toString(),
      minTrades: minTrades.toString(),
    },
    requestPolicy: "network-only",
  });

  return useMemo(() => {
    const filteredTokensPerformancePerIntervalData =
      filteredTokensPerformancePerInterval.data?.get_formatted_tokens_with_performance_intervals_within_period;

    return {
      data: filteredTokensPerformancePerIntervalData?.map((token) => ({
        ...token,
        increase_pct_after: JSON.parse(token.increase_pct_after),
        trades_after: JSON.parse(token.trades_after),
      })),
      error: filteredTokensPerformancePerInterval.error?.message,
      loading: filteredTokensPerformancePerInterval.fetching,
      refetch: queryFilteredTokensPerformancePerInterval,
    };
  }, [
    filteredTokensPerformancePerInterval.data,
    filteredTokensPerformancePerInterval.error,
    filteredTokensPerformancePerInterval.fetching,
    queryFilteredTokensPerformancePerInterval,
  ]);
};
