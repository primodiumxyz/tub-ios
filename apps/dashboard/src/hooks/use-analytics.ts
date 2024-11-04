import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";

export const useAnalyticsData = (): {
  swaps: { hour: Date | null; count: string | null }[] | undefined;
  newTokens: { hour: Date | null; count: string | null }[] | undefined;
  totalSwaps: number | undefined;
  totalNewTokens: number | undefined;
  volumeIntervals: {
    data: { interval_start: Date; token_count: string; total_volume: string }[] | undefined;
    error: string | undefined;
  };
  error: string | undefined;
} => {
  const { from, to } = useAnalyticsParams();
  const { timespan } = useTrackerParams();

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

  const [volumeIntervals] = useQuery({
    query: queries.GetVolumeIntervalsWithinPeriodQuery,
    variables: {
      from,
      to,
      interval: timespan,
    },
    requestPolicy: "network-only",
  });

  return useMemo(
    () => ({
      swaps: swapResult.data?.swaps_hourly,
      newTokens: newTokenResult.data?.new_tokens_hourly,
      totalSwaps: swapResult.data?.swaps_total.aggregate?.count,
      totalNewTokens: newTokenResult.data?.new_tokens_total.aggregate?.count,
      error: swapResult.error?.message || newTokenResult.error?.message,
      volumeIntervals: {
        data: volumeIntervals.data?.volume_intervals_within_period,
        error: volumeIntervals.error?.message,
      },
    }),
    [
      swapResult.data,
      newTokenResult.data,
      swapResult.error,
      newTokenResult.error,
      volumeIntervals.data,
      volumeIntervals.error,
    ],
  );
};
