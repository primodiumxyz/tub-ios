import { useEffect, useMemo } from "react";

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
  useEffect(() => {
    CODEX_SDK.queries
      .listTopTokens({
        networkFilter: NETWORK_FILTER,
        resolution: "60", // time frame for trending results,
        limit: 50, // max limit
      })
      .then(console.log);
  }, []);

  return useMemo(
    () => ({
      // ...
    }),
    [],
  );
};
