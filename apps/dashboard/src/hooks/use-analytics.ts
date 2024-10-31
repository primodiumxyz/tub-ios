import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";

// TODO: maybe support filters (e.g. only pump tokens) for these 3 queries
export const useAnalyticsData = (): {
  swaps: { hour: Date | null; count: string | null }[] | undefined;
  newTokens: { hour: Date | null; count: string | null }[] | undefined;
  totalSwaps: number | undefined;
  totalNewTokens: number | undefined;
  filteredTokensPerInterval: {
    data: { interval_start: Date; token_count: string }[] | undefined;
    error: string | undefined;
  };
  error: string | undefined;
} => {
  const { from, to } = useAnalyticsParams();
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const [swapResult] = useQuery({
    query: queries.GetSwapsInPeriodCountQuery,
    variables: { from, to },
    requestPolicy: "network-only",
  });

  const [newTokenResult] = useQuery({
    query: queries.GetNewTokensInPeriodCountQuery,
    variables: { from, to },
    requestPolicy: "network-only",
  });

  const [filteredTokensPerInterval] = useQuery({
    query: queries.GetFormattedTokensCountForIntervalsWithinPeriodQuery,
    variables: {
      from,
      to,
      interval: timespan,
      increasePct: increasePct.toString(),
      minTrades: minTrades.toString(),
    },
    requestPolicy: "network-only",
  });
  console.log(filteredTokensPerInterval.data);

  return useMemo(
    () => ({
      swaps: swapResult.data?.swaps_hourly,
      newTokens: newTokenResult.data?.new_tokens_hourly,
      totalSwaps: swapResult.data?.swaps_total.aggregate?.count,
      totalNewTokens: newTokenResult.data?.new_tokens_total.aggregate?.count,
      error: swapResult.error?.message || newTokenResult.error?.message,
      filteredTokensPerInterval: {
        data: filteredTokensPerInterval.data?.get_formatted_tokens_intervals_within_period_aggregate,
        error: filteredTokensPerInterval.error?.message,
      },
    }),
    [
      swapResult.data,
      newTokenResult.data,
      swapResult.error,
      newTokenResult.error,
      filteredTokensPerInterval.data,
      filteredTokensPerInterval.error,
    ],
  );
};
