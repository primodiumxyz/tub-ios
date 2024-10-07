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

// TODO(review): why is it not inferring the type?
type pumping_tokens_result = {
  created_at: string;
  increase_pct: number;
  latest_price: number;
  mint: string;
  name: string;
  symbol: string;
  token_id: string;
  trades: number;
}[];

export const useTokens = () => {
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const since = useRef(new Date(new Date().getTime() - timespan * 1000));
  const [pumpingTokensResult] = useSubscription({
    query: subscriptions.GetPumpingTokensWithFiltersSubscription,
    variables: { since: since.current, minIncreasePct: increasePct.toString(), minTrades: minTrades.toString() },
  });

  const tokens = useMemo(() => {
    if (!pumpingTokensResult.data?.pumping_tokens) return [];
    return (pumpingTokensResult.data.pumping_tokens as pumping_tokens_result).map((token) => ({
      mint: token.mint,
      latestPrice: token.latest_price,
      increasePct: token.increase_pct,
      trades: token.trades,
      platform: token.name,
    }));
  }, [pumpingTokensResult.data]);

  useEffect(() => {
    const interval = setInterval(() => {
      since.current = new Date(new Date().getTime() - timespan * 1000);
    }, 1000);
    return () => clearInterval(interval);
  }, [timespan]);

  return useMemo(
    () => ({
      tokens,
      fetching: pumpingTokensResult.fetching && pumpingTokensResult.data === undefined,
      error: pumpingTokensResult.error?.message,
    }),
    [tokens, pumpingTokensResult.fetching, pumpingTokensResult.data, pumpingTokensResult.error],
  );
};
