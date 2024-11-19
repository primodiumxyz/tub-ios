import { useCallback, useEffect, useMemo, useState } from "react";
import { RankingDirection, TokenRankingAttribute } from "@codex-data/sdk/dist/sdk/generated/graphql";

import { useServer } from "@/hooks/use-server";
import { PUMP_FUN_ID } from "@/lib/constants";
import { Token } from "@/lib/types";

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [fetching, setFetching] = useState(true);
  const [error, setError] = useState<string | undefined>(undefined);

  const { codexSdk } = useServer();

  const fetchTokens = useCallback(async () => {
    try {
      if (!codexSdk) return;
      setFetching(true);
      const res = await codexSdk.queries.filterTokens({
        // see: https://docs.codex.io/reference/input-objects#tokenfilters
        filters: {
          exchangeId: [PUMP_FUN_ID],
          trendingIgnored: false,
          potentialScam: false,
        },
        // see: https://docs.codex.io/reference/input-objects#tokenranking
        rankings: {
          attribute: TokenRankingAttribute.Volume1,
          direction: RankingDirection.Desc,
        },
        limit: 50,
      });

      const formattedTokens =
        res.filterTokens?.results?.map((t) => ({
          mint: t?.token?.address,
          imageUri:
            t?.token?.info?.imageLargeUrl ??
            t?.token?.info?.imageSmallUrl ??
            t?.token?.info?.imageThumbUrl ??
            undefined,
          name: t?.token?.info?.name ?? undefined,
          symbol: t?.token?.info?.symbol,
          latestPrice: Number(t?.priceUSD ?? 0),
          liquidity: t?.liquidity ?? undefined,
          marketCap: t?.marketCap ?? undefined,
          volume: t?.volume1 ?? undefined,
          pairId: t?.pair?.id,
          priceChange: {
            60: Number(t?.change1 ?? 0),
            240: Number(t?.change4 ?? 0),
            720: Number(t?.change12 ?? 0),
            1440: Number(t?.change24 ?? 0),
          },
          transactions: {
            60: t?.txnCount1 ?? 0,
            240: t?.txnCount4 ?? 0,
            720: t?.txnCount12 ?? 0,
            1440: t?.txnCount24 ?? 0,
          },
          uniqueBuys: {
            60: t?.uniqueBuys1 ?? 0,
            240: t?.uniqueBuys4 ?? 0,
            720: t?.uniqueBuys12 ?? 0,
            1440: t?.uniqueBuys24 ?? 0,
          },
          uniqueSells: {
            60: t?.uniqueSells1 ?? 0,
            240: t?.uniqueSells4 ?? 0,
            720: t?.uniqueSells12 ?? 0,
            1440: t?.uniqueSells24 ?? 0,
          },
        })) ?? [];
      setTokens(formattedTokens);
      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  }, [codexSdk]);

  useEffect(() => {
    fetchTokens();
    const interval = setInterval(() => fetchTokens(), 5_000);
    return () => clearInterval(interval);
  }, [fetchTokens]);

  return useMemo(
    () => ({
      tokens,
      fetching,
      error,
    }),
    [tokens, fetching, error],
  );
};
