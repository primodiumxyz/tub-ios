import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Token } from "@/lib/types";

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const [tokensRes] = useSubscription({
    query: subscriptions.GetTopTokensByVolumeSubscription,
    variables: {
      interval: "5m",
    },
  });

  return useMemo(
    () => ({
      tokens:
        tokensRes.data?.token_stats_interval_comp.map((t) => ({
          mint: t.token_mint,
          name: t.token_metadata_name,
          symbol: t.token_metadata_symbol,
          imageUri: t.token_metadata_image_uri ?? undefined,
          volumeUsd: Number(t.total_volume_usd),
          tradeCount: Number(t.total_trades),
          priceChangePct: Number(t.price_change_pct),
        })) ?? [],
      fetching: tokensRes.fetching,
      error: tokensRes.error?.message,
    }),
    [tokensRes.data, tokensRes.fetching, tokensRes.error],
  );
};
