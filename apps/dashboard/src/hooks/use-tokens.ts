import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { useTrackerParams } from "@/hooks/use-tracker-params";

export type Token = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
  platform: string;
  name: string;
  symbol: string;
  id: string;
};

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const [filteredTokensResult] = useSubscription({
    query: subscriptions.GetFilteredTokensIntervalSubscription,
    variables: {
      interval: timespan,
      minIncreasePct: increasePct.toString(),
      minTrades: minTrades.toString(),
    },
  });

  const tokens = useMemo(() => {
    if (!filteredTokensResult.data?.get_formatted_tokens_interval) return [];
    return filteredTokensResult.data.get_formatted_tokens_interval.map((token) => ({
      mint: token.mint,
      latestPrice: Number(token.latest_price),
      increasePct: Number(token.increase_pct),
      trades: Number(token.trades),
      platform: token.platform,
      name: token.name,
      symbol: token.symbol,
      id: token.token_id,
    }));
  }, [filteredTokensResult.data]);

  return useMemo(
    () => ({
      tokens,
      fetching: filteredTokensResult.fetching && filteredTokensResult.data === undefined,
      error: filteredTokensResult.error?.message,
    }),
    [tokens, filteredTokensResult.fetching, filteredTokensResult.data, filteredTokensResult.error],
  );
};
