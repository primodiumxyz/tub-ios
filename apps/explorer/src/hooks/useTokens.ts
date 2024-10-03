import { useEffect, useMemo, useState } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { useTrackerParams } from "@/hooks/useTrackerParams";

export type Token = {
  mint: string;
  latestPrice: number;
  increasePct: number;
  trades: number;
};

type PriceData = {
  price: string;
  token_relationship: {
    mint: string;
  };
};

export const useTokens = () => {
  const { timespan } = useTrackerParams();
  const [tokens, setTokens] = useState<Token[]>([]);

  const [priceHistory] = useSubscription({
    query: subscriptions.GetAllOnchainTokensPriceHistorySinceSubscription,
    variables: { since: new Date(new Date().getTime() - timespan * 1000) },
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
      const minPrice = Math.min(...trades);
      const latestPrice = trades[trades.length - 1];
      const increasePct = ((latestPrice - minPrice) / minPrice) * 100;

      return {
        mint,
        latestPrice,
        increasePct,
        trades: trades.length,
      };
    });

    setTokens(tokensWithData);
  };

  useEffect(() => {
    formatTokens(priceHistory.data?.token_price_history as PriceData[]);
  }, [priceHistory.data]);

  return useMemo(() => ({ tokens }), [tokens]);
};
