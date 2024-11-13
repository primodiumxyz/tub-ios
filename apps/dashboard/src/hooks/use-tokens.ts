import { useEffect, useMemo, useState } from "react";

import { CODEX_SDK, NETWORK_FILTER, PUMP_FUN_ADDRESS, RESOLUTION } from "@/lib/constants";
import { Token } from "@/lib/types";

// TODO: filter only pump.fun tokens
export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [fetching, setFetching] = useState(true);
  const [error, setError] = useState<string | undefined>(undefined);

  const fetchTokens = async () => {
    try {
      setFetching(true);
      const res = await CODEX_SDK.queries.listTopTokens({
        networkFilter: NETWORK_FILTER,
        resolution: RESOLUTION, // time frame for trending results,
        limit: 50, // max limit
      });
      console.log(res);

      const formattedTokens =
        res.listTopTokens
          ?.filter((t) => t.exchanges.some((e) => e.address === PUMP_FUN_ADDRESS))
          .map((t) => ({
            mint: t.address,
            imageUri: t.imageLargeUrl ?? t.imageSmallUrl ?? t.imageThumbUrl ?? null,
            name: t.name,
            symbol: t.symbol,
            latestPrice: t.price,
            liquidity: t.liquidity,
            marketCap: t.marketCap ?? null,
            volume: t.volume,
            priceChange: {
              60: t.priceChange1 ?? 0,
              240: t.priceChange4 ?? 0,
              720: t.priceChange12 ?? 0,
              1440: t.priceChange24 ?? 0,
            },
            transactions: {
              60: t.txnCount1 ?? 0,
              240: t.txnCount4 ?? 0,
              720: t.txnCount12 ?? 0,
              1440: t.txnCount24 ?? 0,
            },
            uniqueBuys: {
              60: t.uniqueBuys1 ?? 0,
              240: t.uniqueBuys4 ?? 0,
              720: t.uniqueBuys12 ?? 0,
              1440: t.uniqueBuys24 ?? 0,
            },
            uniqueSells: {
              60: t.uniqueSells1 ?? 0,
              240: t.uniqueSells4 ?? 0,
              720: t.uniqueSells12 ?? 0,
              1440: t.uniqueSells24 ?? 0,
            },
          })) ?? [];
      setTokens(formattedTokens);
      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  };

  useEffect(() => {
    fetchTokens();
    const interval = setInterval(() => fetchTokens(), 5_000);
    return () => clearInterval(interval);
  }, []);

  return useMemo(
    () => ({
      tokens,
      fetching,
      error,
    }),
    [tokens, fetching, error],
  );
};
