import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Token } from "@/lib/types";

type UseTokensResult = {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
};

/**
 * Hook to get the updated top-ranked tokens by 30min volume
 *
 * @returns The tokens with loading & error state {@link UseTokensResult}
 */
export const useTokens = (): UseTokensResult => {
  const [tokensRes] = useSubscription({
    query: subscriptions.GetTopTokensByVolumeSubscription,
  });

  return useMemo(
    () => ({
      tokens:
        tokensRes.data?.token_rolling_stats_30min.map((t) => ({
          mint: t.mint,
          name: t.name,
          symbol: t.symbol,
          imageUri: t.image_uri ?? undefined,
          volumeUsd: Number(t.volume_usd_30m),
          tradeCount: Number(t.trades_30m),
          priceChangePct: Number(t.price_change_pct_30m),
          supply: Number(t.supply),
          latestPriceUsd: Number(t.latest_price_usd),
        })) ?? [],
      fetching: tokensRes.fetching,
      error: tokensRes.error?.message,
    }),
    [tokensRes.data, tokensRes.fetching, tokensRes.error],
  );
};
