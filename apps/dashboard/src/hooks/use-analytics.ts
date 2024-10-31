import { useMemo } from "react";
import { useQuery } from "urql";

import { queries } from "@tub/gql";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";

export const useAnalyticsData = (): {
  swaps: { hour: Date | null; count: string | null }[] | undefined;
  newTokens: { hour: Date | null; count: string | null }[] | undefined;
  totalSwaps: number | undefined;
  totalNewTokens: number | undefined;
  error: string | undefined;
} => {
  const { from, to } = useAnalyticsParams();

  const [swapResult] = useQuery({
    query: queries.GetSwapsInPeriodQuery,
    variables: { from, to },
    requestPolicy: "network-only",
  });
  console.log(swapResult.data);

  const [newTokenResult] = useQuery({
    query: queries.GetNewTokensInPeriodQuery,
    variables: { from, to },
    requestPolicy: "network-only",
  });

  return useMemo(
    () => ({
      swaps: swapResult.data?.swaps_hourly,
      newTokens: newTokenResult.data?.new_tokens_hourly,
      totalSwaps: swapResult.data?.swaps_total.aggregate?.count,
      totalNewTokens: newTokenResult.data?.new_tokens_total.aggregate?.count,
      error: swapResult.error?.message || newTokenResult.error?.message,
    }),
    [swapResult.data, newTokenResult.data, swapResult.error, newTokenResult.error],
  );
};
