import { useEffect, useMemo, useRef, useState } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { useTrackerParams } from "@/hooks/useTrackerParams";

export type Token = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
  platform: string;
};

type PriceData = {
  price: string;
  token_relationship: {
    mint: string;
    name: string;
  };
};

export const useTokens = () => {
  const { timespan } = useTrackerParams();
  const [tokens, setTokens] = useState<Token[]>([]);

  const since = useRef(new Date(new Date().getTime() - timespan * 1000));
  const [priceHistory] = useSubscription({
    query: subscriptions.GetAllOnchainTokensPriceHistorySinceSubscription,
    variables: { since: since.current },
  });

  const formatTokens = (data: PriceData[] | undefined) => {
    if (!data) return;

    const tradesPerToken = data.reduce(
      (acc, curr) => {
        if (!acc[curr.token_relationship.mint]) acc[curr.token_relationship.mint] = [];
        acc[curr.token_relationship.mint].push(Number(curr.price));
        return acc;
      },
      {} as Record<string, number[]>,
    );

    const tokensWithData = Object.entries(tradesPerToken).map(([mint, trades]) => {
      // TODO: we need to decide which algorithm to get the price increase:
      // 1. (current and usual) we calculate the difference between the current (latest) price and the price at the start of the timespan
      // (which would be consistent with candles)
      // 2. we calculate the difference between the current (latest) price and the lowest price during the timespan
      // which seems like it could make sense? because on a 30s timespan, if it goes down then up again, it could very well be pumping on that lower
      // timespan, meaning that the timespan we choose is actually a maximum timespan?
      // const minPrice = Math.min(...trades);
      const minPrice = trades[0];
      const latestPrice = trades[trades.length - 1];
      const increasePct = ((latestPrice - minPrice) / minPrice) * 100;
      const platform = data.find((d) => d.token_relationship.mint === mint)?.token_relationship.name;

      return {
        mint,
        latestPrice,
        increasePct,
        trades: trades.length,
        platform: platform ?? "",
      };
    });

    setTokens(tokensWithData);
  };

  useEffect(() => {
    formatTokens(priceHistory.data?.token_price_history as PriceData[]);
  }, [priceHistory.data]);

  useEffect(() => {
    const interval = setInterval(() => {
      since.current = new Date(new Date().getTime() - timespan * 1000);
    }, 1000);
    return () => clearInterval(interval);
  }, [timespan]);

  return useMemo(() => ({ tokens, fetching: priceHistory.fetching, error: priceHistory.error?.message }), [tokens]);
};
