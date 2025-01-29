import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Stats, StatsFilters } from "@/lib/types";

export const useStats = (
  filters: StatsFilters,
): {
  stats: Stats | undefined;
  fetching: boolean;
  error: string | undefined;
} => {
  const [statsRes] = useSubscription({
    query: subscriptions.GetStatsSubscription,
    variables: { userWallet: filters.userWallet || undefined, tokenMint: filters.tokenMint || undefined },
  });

  return useMemo(() => {
    const stats = statsRes.data?.transaction_analytics[0];

    return {
      stats: stats
        ? {
            pnlUsd: Number(stats?.total_pnl_usd),
            volumeUsd: Number(stats?.total_volume_usd),
            tradeCount: Number(stats?.trade_count),
            successRate: Number(stats?.success_rate),
          }
        : undefined,
      fetching: statsRes.fetching,
      error: statsRes.error?.message,
    };
  }, [statsRes.data, statsRes.fetching, statsRes.error, filters]);
};
