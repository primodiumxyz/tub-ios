import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Interval, Token } from "@/lib/types";

export const useTokens = (
  interval: Interval,
): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const [tokensRes] = useSubscription({
    query: subscriptions.GetTopTokensByVolumeSubscription,
    variables: {
      interval,
    },
  });

  return useMemo(
    () => ({
      tokens:
        tokensRes.data?.token_stats_interval_cache.map((t) => ({
          mint: t.token_mint,
          name: t.token_metadata_name,
          symbol: t.token_metadata_symbol,
          imageUri: t.token_metadata_image_uri ?? undefined,
          volumeUsd: Number(t.total_volume_usd),
          tradeCount: Number(t.total_trades),
          priceChangePct: Number(t.price_change_pct),
          supply: Number(t.token_metadata_supply),
          latestPriceUsd: Number(t.latest_price_usd),
        })) ?? [],
      fetching: tokensRes.fetching,
      error: tokensRes.error?.message,
    }),
    [tokensRes.data, tokensRes.fetching, tokensRes.error],
  );
};
