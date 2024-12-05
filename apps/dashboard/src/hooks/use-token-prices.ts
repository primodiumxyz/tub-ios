import { useCallback, useEffect, useState } from "react";

import { Token, TokenPrice } from "@/lib/types";

export const useTokenPrices = (
  token: Token,
  intervalSeconds: number = 75,
  onUpdate: (price: TokenPrice) => void,
): { tokenPrices: TokenPrice[]; fetching: boolean; error: string | null } => {
  const [tokenPrices, setTokenPrices] = useState<TokenPrice[]>([]);
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchChartData = useCallback(async () => {
    try {
      setFetching(true);
      // TODO: implement
      // const now = Math.floor(Date.now() / 1000);

      setTokenPrices([]);
      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  }, []);

  const subscribeToChartData = useCallback(async () => {
    // TODO: implement
  }, []);

  useEffect(() => {
    fetchChartData().then(subscribeToChartData);
  }, [intervalSeconds, fetchChartData, subscribeToChartData]);

  return {
    tokenPrices,
    fetching,
    error,
  };
};
