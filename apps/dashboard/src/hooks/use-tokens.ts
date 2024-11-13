import { useEffect, useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { CODEX_SDK, NETWORK_FILTER } from "@/lib/constants";

export type Token = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
  volume: number;
  name: string;
  symbol: string;
  uri: string;
  mintBurnt: boolean;
  freezeBurnt: boolean;
  id: string;
};

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const { timespan, minTrades, minVolume, mintBurnt, freezeBurnt } = useTrackerParams();

  const [filteredTokensResult] = useSubscription({
    query: subscriptions.GetFilteredTokensIntervalSubscription,
    variables: {
      interval: timespan,
      minTrades: minTrades.toString(),
      minVolume: minVolume.toString(),
      mintBurnt,
      freezeBurnt,
    },
  });

  useEffect(() => {
    CODEX_SDK.queries
      .listTopTokens({
        networkFilter: NETWORK_FILTER,
        resolution: "60", // time frame for trending results,
        limit: 50, // max limit
      })
      .then(console.log);
  }, []);

  const tokens = useMemo(() => {
    if (!filteredTokensResult.data?.formatted_tokens_interval) return [];
    return filteredTokensResult.data.formatted_tokens_interval.map((token) => ({
      mint: token.mint,
      latestPrice: Number(token.latest_price),
      increasePct: Number(token.increase_pct),
      trades: Number(token.trades),
      volume: Number(token.volume),
      name: token.name ?? "NAME",
      symbol: token.symbol ?? "SYMBOL",
      uri: token.uri ?? "",
      mintBurnt: token.mint_burnt ?? false,
      freezeBurnt: token.freeze_burnt ?? false,
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
