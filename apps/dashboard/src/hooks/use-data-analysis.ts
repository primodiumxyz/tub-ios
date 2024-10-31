import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { AFTER_INTERVALS } from "@/lib/constants";
import { FilteredTokensPerformancePerIntervalData } from "@/lib/types";

export const useDataAnalysisData = (): {
  data: FilteredTokensPerformancePerIntervalData[] | undefined;
  error: string | undefined;
  loading: boolean;
  refetch: () => void;
} => {
  const { from, to } = useAnalyticsParams();
  const { timespan } = useTrackerParams();

  const [filteredTokensPerformancePerInterval, queryFilteredTokensPerformancePerInterval] = useQuery({
    query: queries.GetFormattedTokensWithPerformanceForIntervalsWithinPeriodQuery,
    variables: {
      from,
      to,
      interval: timespan,
      afterIntervals: AFTER_INTERVALS.join(","),
    },
    requestPolicy: "network-only",
  });

  return useMemo(
    () => ({
      // TODO: fix null values when they are not nullable
      data: filteredTokensPerformancePerInterval.data?.formatted_tokens_with_performance_intervals_within_period,
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
