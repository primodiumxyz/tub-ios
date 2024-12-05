import { useEffect, useMemo, useRef } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Token, TokenPrice } from "@/lib/types";

export const useTokenPrices = (
  token: Token,
  intervalSeconds: number = 75,
  onUpdate: (price: TokenPrice) => void,
): { tokenPrices: TokenPrice[]; fetching: boolean; error?: string } => {
  const now = useMemo(() => Date.now(), []);
  const initialPrices = useRef<TokenPrice[]>([]);
  const lastPriceTimestamp = useRef(0);

  const [tokenPricesRes] = useSubscription({
    query: subscriptions.GetTokenPricesSinceSubscription,
    variables: { token: token.mint, since: new Date(now - intervalSeconds * 1000) },
  });

  const filterOutDuplicatePriceTimestamps = (prices: TokenPrice[]) =>
    prices.filter((price, index, self) => self.findIndex((p) => p.timestamp === price.timestamp) === index);

  useEffect(() => {
    const prices = tokenPricesRes.data?.api_trade_history;

    if (prices && !initialPrices.current.length) {
      console.log("setting initial prices");
      initialPrices.current = filterOutDuplicatePriceTimestamps(
        prices.map((price) => ({
          price: Number(price.token_price_usd),
          timestamp: new Date(price.created_at).getTime(),
        })),
      );

      lastPriceTimestamp.current = initialPrices.current[initialPrices.current.length - 1].timestamp;
    } else if (prices) {
      console.log("updating prices");
      // Get all entries after the last price timestamp
      const pricesAfterLastPrice = prices.filter(
        (price) => new Date(price.created_at).getTime() > lastPriceTimestamp.current,
      );

      const newPrices = filterOutDuplicatePriceTimestamps(
        pricesAfterLastPrice.map((price) => ({
          price: Number(price.token_price_usd),
          timestamp: new Date(price.created_at).getTime(),
        })),
      );

      newPrices.forEach(onUpdate);
      lastPriceTimestamp.current = new Date(prices[prices.length - 1].created_at).getTime();
    }
  }, [tokenPricesRes]);

  return {
    tokenPrices: initialPrices.current,
    fetching: tokenPricesRes.fetching,
    error: tokenPricesRes.error?.message,
  };
};
