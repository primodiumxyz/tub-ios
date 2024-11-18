import { useEffect, useState } from "react";

import { CODEX_SDK } from "@/lib/constants";
import { Token, TokenCandle, TokenCandles } from "@/lib/types";

export const useTokenCandles = (
  token: Token,
  onUpdate: (candle: TokenCandle) => void,
): { tokenCandles: TokenCandles | undefined; fetching: boolean; error: string | null } => {
  const [tokenCandles, setTokenCandles] = useState<TokenCandles | undefined>();
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCandlesData = async () => {
    try {
      setFetching(true);

      const res = await CODEX_SDK.queries.getBars({
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
  };

  const subscribeToCandlesData = async () => {
    CODEX_SDK.subscriptions.onBarsUpdated(
      {
        pairId: token.pairId,
      },
      {
        next(value) {
          if (value.errors) {
            setError(value.errors[0].message);
            return;
          }

          if (!value.data?.onBarsUpdated?.aggregates?.r1?.token) return;

          onUpdate({
            o: value.data.onBarsUpdated.aggregates.r1.token.o,
            h: value.data.onBarsUpdated.aggregates.r1.token.h,
            l: value.data.onBarsUpdated.aggregates.r1.token.l,
            c: value.data.onBarsUpdated.aggregates.r1.token.c,
            v: value.data.onBarsUpdated.aggregates.r1.token.v ?? null,
            t: value.data.onBarsUpdated.aggregates.r1.token.t,
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
  };

  useEffect(() => {
    fetchCandlesData().then(subscribeToCandlesData);
  }, []);

  return {
    tokenCandles,
    fetching,
    error,
  };
};
