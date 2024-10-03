import { useCallback, useEffect, useMemo, useState } from "react";

import { useTrackerParams } from "@/hooks/useTrackerParams";

export type PumpingToken = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
  pumping: boolean;
};

export const usePumpingTokens = () => {
  const { timespan, increasePct, minTrades } = useTrackerParams();
  const params = useMemo(() => ({ timespan, increasePct, minTrades }), [timespan, increasePct, minTrades]);
  const { priceData } = useTradesWatcher(params.timespan);

  const [pumpingTokens, setPumpingTokens] = useState<PumpingToken[]>([]);

  const calculatePumpingTokens = useCallback(
    (data: PriceData[]) => {
      const { increasePct: reqIncreasePct, minTrades } = params;

      const tradesPerToken = data.reduce(
        (acc, curr) => {
          if (!acc[curr.mint]) acc[curr.mint] = [];
          acc[curr.mint].push(curr.price);
          return acc;
        },
        {} as Record<string, number[]>,
      );

      const tokensWithData = Object.entries(tradesPerToken).map(([mint, trades]) => {
        const minPrice = Math.min(...trades);
        const latestPrice = trades[trades.length - 1];
        const increasePct = ((latestPrice - minPrice) / minPrice) * 100;
        const pumping = increasePct >= reqIncreasePct && trades.length >= minTrades;

        return {
          mint,
          latestPrice,
          increasePct,
          trades: trades.length,
          pumping,
        };
      });

      setPumpingTokens(tokensWithData.filter((token) => token.pumping));
    },
    [params],
  );

  useEffect(() => {
    calculatePumpingTokens(priceData);
  }, [priceData, calculatePumpingTokens]);

  return useMemo(() => ({ pumpingTokens }), [pumpingTokens]);
};
