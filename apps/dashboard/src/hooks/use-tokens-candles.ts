import { useEffect, useMemo, useRef } from "react";
import { CandlestickData, Time } from "lightweight-charts";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Token } from "@/lib/types";

export const useTokenCandles = (
  token: Token,
  onUpdate: (candle: CandlestickData) => void,
): { tokenCandles: CandlestickData[] | undefined; fetching: boolean; error?: string } => {
  const now = useMemo(() => Date.now(), []);
  const initialCandles = useRef<CandlestickData[]>([]);
  const lastCandleTimestamp = useRef(0);

  const [tokenCandlesRes] = useSubscription({
    query: subscriptions.GetTokenCandlesSinceSubscription,
    variables: { token: token.mint, since: new Date(now - 60 * 60 * 1000) },
  });

  const formatCandles = (
    candles: {
      bucket: Date;
      open_price_usd: string;
      high_price_usd: string;
      low_price_usd: string;
      close_price_usd: string;
    }[],
  ) =>
    candles.map((candle) => ({
      time: new Date(candle.bucket).getTime() as Time,
      open: Number(candle.open_price_usd),
      high: Number(candle.high_price_usd),
      low: Number(candle.low_price_usd),
      close: Number(candle.close_price_usd),
    }));

  useEffect(() => {
    const candles = tokenCandlesRes.data?.token_candles_history_1min;

    if (candles && !initialCandles.current.length) {
      initialCandles.current = formatCandles(candles);
      lastCandleTimestamp.current = Number(initialCandles.current[initialCandles.current.length - 1].time);
    } else if (candles) {
      // Get all entries after the last price timestamp
      const candlesAfterLastCandle = candles.filter(
        (candle) => new Date(candle.bucket).getTime() >= lastCandleTimestamp.current,
      );

      const newCandles = formatCandles(candlesAfterLastCandle);

      newCandles.forEach(onUpdate);
      lastCandleTimestamp.current = Number(newCandles[newCandles.length - 1].time);
    }
  }, [tokenCandlesRes]);

  return {
    tokenCandles: initialCandles.current,
    fetching: initialCandles.current.length ? false : tokenCandlesRes.fetching,
    error: tokenCandlesRes.error?.message,
  };
};
