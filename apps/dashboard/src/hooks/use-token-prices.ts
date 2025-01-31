import { useEffect, useMemo, useRef } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { Token, TokenPrice } from "@/lib/types";

type UseTokenPricesResult = {
  tokenPrices: TokenPrice[];
  fetching: boolean;
  error?: string;
};

/**
 * Hook to get the updated price for a token for a given interval
 *
 * @param token - The token to get prices for
 * @param intervalSeconds - The interval in seconds to get prices for
 * @param onUpdate - The callback to call when a price is updated
 * @returns The token prices with loading & error state {@link UseTokenPricesResult}
 */
export const useTokenPrices = (
  token: Token,
  intervalSeconds: number = 75,
  onUpdate?: (price: TokenPrice) => void,
): UseTokenPricesResult => {
  const now = useMemo(() => Date.now(), []);
  const initialPrices = useRef<TokenPrice[]>([]);
  const lastPriceTimestamp = useRef(0);

  const [tokenPricesRes] = useSubscription({
    query: subscriptions.GetTokenPricesSinceSubscription,
    variables: { token: token.mint, since: new Date(now - intervalSeconds * 1000) },
  });

  const formatPrices = (prices: { token_price_usd: string; created_at: Date }[]) =>
    prices.map((price) => ({
      price: Number(price.token_price_usd),
      timestamp: new Date(price.created_at).getTime(),
    }));

  const filterOutDuplicatePriceTimestamps = (prices: TokenPrice[]) =>
    prices.filter((price, index, self) => self.findIndex((p) => p.timestamp === price.timestamp) === index);

  useEffect(() => {
    const prices = tokenPricesRes.data?.api_trade_history;

    if (prices && !initialPrices.current.length) {
      initialPrices.current = filterOutDuplicatePriceTimestamps(formatPrices(prices));
      lastPriceTimestamp.current = initialPrices.current[initialPrices.current.length - 1].timestamp;
    } else if (prices) {
      // Get all entries after the last price timestamp
      const pricesAfterLastPrice = prices.filter(
        (price) => new Date(price.created_at).getTime() > lastPriceTimestamp.current,
      );

      const newPrices = filterOutDuplicatePriceTimestamps(formatPrices(pricesAfterLastPrice));

      newPrices.forEach((price) => onUpdate?.(price));
      lastPriceTimestamp.current = new Date(prices[prices.length - 1].created_at).getTime();
    }
  }, [tokenPricesRes]);

  return {
    tokenPrices: initialPrices.current,
    fetching: initialPrices.current.length ? false : tokenPricesRes.fetching,
    error: tokenPricesRes.error?.message,
  };
};
