import { useCallback, useEffect, useState } from "react";

import { Token, TokenCandles } from "@/lib/types";

export const useTokenCandles = (
  token: Token,
  onUpdate: (candle: TokenCandle) => void,
): { tokenCandles: TokenCandles | undefined; fetching: boolean; error: string | null } => {
  const [tokenCandles, setTokenCandles] = useState<TokenCandles | undefined>();
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCandlesData = useCallback(async () => {
    try {
      setFetching(true);

      // TODO: implement

      setTokenCandles(undefined);

      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  }, [token.mint]);

  const subscribeToCandlesData = useCallback(async () => {
    // TODO: implement
  }, [token.mint]);

  useEffect(() => {
    fetchCandlesData().then(subscribeToCandlesData);
  }, [fetchCandlesData, subscribeToCandlesData]);

  return {
    tokenCandles,
    fetching,
    error,
  };
};
