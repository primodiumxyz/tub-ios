import { useCallback, useEffect, useState } from "react";

import { useServer } from "@/hooks/use-server";
import { Token, TokenCandle, TokenCandles } from "@/lib/types";

export const useTokenCandles = (
  token: Token,
  onUpdate: (candle: TokenCandle) => void,
): { tokenCandles: TokenCandles | undefined; fetching: boolean; error: string | null } => {
  const [tokenCandles, setTokenCandles] = useState<TokenCandles | undefined>();
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { codexSdk } = useServer();

  const fetchCandlesData = useCallback(async () => {
    try {
      if (!codexSdk) return;
      setFetching(true);

      const res = await codexSdk.queries.getBars({
        from: Math.floor(Date.now() / 1000) - 60 * 30, // 30 min ago
        to: Math.floor(Date.now() / 1000),
        resolution: "1", // 1 min candles
        symbol: token.pairId ?? "",
      });

      if (!res.getBars) return;
      setTokenCandles({
        o: res.getBars.o,
        h: res.getBars.h,
        l: res.getBars.l,
        c: res.getBars.c,
        v: res.getBars.v,
        t: res.getBars.t,
      });

      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  }, [codexSdk, token.pairId]);

  const subscribeToCandlesData = useCallback(async () => {
    if (!codexSdk) return;
    codexSdk.subscriptions.onBarsUpdated(
      {
        pairId: token.pairId,
      },
      {
        next(value) {
          if (value.errors) {
            setError(value.errors[0].message);
            return;
          }

          if (!value.data?.onBarsUpdated?.aggregates?.r1?.usd) return;

          onUpdate({
            o: value.data.onBarsUpdated.aggregates.r1.usd.o,
            h: value.data.onBarsUpdated.aggregates.r1.usd.h,
            l: value.data.onBarsUpdated.aggregates.r1.usd.l,
            c: value.data.onBarsUpdated.aggregates.r1.usd.c,
            v: value.data.onBarsUpdated.aggregates.r1.usd.v ?? null,
            t: value.data.onBarsUpdated.aggregates.r1.usd.t,
          });
        },
        complete() {
          console.log("Price subscription completed");
        },
        error(err) {
          setError(String(err));
        },
      },
    );
  }, [codexSdk, token.pairId]);

  useEffect(() => {
    fetchCandlesData().then(subscribeToCandlesData);
  }, [fetchCandlesData, subscribeToCandlesData]);

  return {
    tokenCandles,
    fetching,
    error,
  };
};
