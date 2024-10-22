import { useEffect, useMemo, useRef } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { useTrackerParams } from "@/hooks/useTrackerParams";

export type Token = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
  platform: string;
};

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const since = useRef(new Date(new Date().getTime() - timespan * 1000));
  const [filteredTokensResult] = useSubscription({
    query: subscriptions.GetFilteredTokensSubscription,
    variables: { since: since.current, minIncreasePct: increasePct.toString(), minTrades: minTrades.toString() },
  });

  const tokens = useMemo(() => {
    if (!filteredTokensResult.data?.get_formatted_tokens_since) return [];
    return filteredTokensResult.data.get_formatted_tokens_since.map((token) => ({
      mint: token.mint,
      latestPrice: Number(token.latest_price),
      increasePct: Number(token.increase_pct),
      trades: Number(token.trades),
      platform: token.platform ?? "",
    }));
  }, [filteredTokensResult.data]);

  useEffect(() => {
    const interval = setInterval(() => {
      since.current = new Date(new Date().getTime() - timespan * 1000);
    }, 1000);
    return () => clearInterval(interval);
  }, [timespan]);

  return useMemo(
    () => ({
      tokens,
      fetching: filteredTokensResult.fetching && filteredTokensResult.data === undefined,
      error: filteredTokensResult.error?.message,
    }),
    [tokens, filteredTokensResult.fetching, filteredTokensResult.data, filteredTokensResult.error],
  );
};
