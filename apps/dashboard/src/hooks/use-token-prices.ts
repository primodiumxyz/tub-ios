import { useEffect, useRef, useState } from "react";
import { EventType, QuoteToken } from "@codex-data/sdk/dist/sdk/generated/graphql";

import { CODEX_SDK, NETWORK_FILTER } from "@/lib/constants";
import { Token, TokenPrice } from "@/lib/types";

export const useTokenPrices = (
  token: Token,
  intervalSeconds: number = 75,
  onUpdate: (price: TokenPrice) => void,
): { tokenPrices: TokenPrice[]; fetching: boolean; error: string | null } => {
  const [tokenPrices, setTokenPrices] = useState<TokenPrice[]>([]);
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const lastTimestamp = useRef(0);

  const fetchChartData = async () => {
    try {
      setFetching(true);
      const now = Math.floor(Date.now() / 1000);
      const chunks = [];

      // Calculate number of chunks needed based on interval
      const numChunks = Math.ceil(intervalSeconds / 25);

      // Create chunks of 25 timestamps each (the max for a query)
      for (let i = 0; i < numChunks; i++) {
        const chunkSize = Math.min(25, intervalSeconds - i * 25);
        const inputs = Array.from({ length: chunkSize }, (_, index) => ({
          address: token.mint ?? "",
          networkId: NETWORK_FILTER[0],
          timestamp: now - (intervalSeconds - (i * 25 + index)),
        }));
        chunks.push(inputs);
      }

      // Fetch data for each chunk
      const results = await Promise.all(chunks.map((inputs) => CODEX_SDK.queries.getTokenPrices({ inputs })));

      // Combine and sort results
      const combinedPrices = results
        .flatMap((res) => res.getTokenPrices || [])
        .sort((a, b) => (a?.timestamp ?? 0) - (b?.timestamp ?? 0))
        .reduce((acc: TokenPrice[], price) => {
          const lastPrice = acc[acc.length - 1]?.price ?? null;
          const currentPrice = price?.priceUsd ?? 0;

          // Only add price if it's different from the last one
          if (lastPrice !== currentPrice) {
            acc.push({
              timestamp: price?.timestamp ?? 0,
              price: currentPrice,
            });
          }
          return acc;
        }, []);

      setTokenPrices(combinedPrices);
      setFetching(false);
      lastTimestamp.current = combinedPrices[combinedPrices.length - 1]?.timestamp ?? 0;
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  };

  const subscribeToChartData = async () => {
    CODEX_SDK.subscriptions.onTokenEventsCreated(
      {
        input: {
          tokenAddress: token.mint ?? "",
          networkId: NETWORK_FILTER[0],
        },
      },
      {
        next(value) {
          if (value.errors) {
            setError(value.errors[0].message);
            return;
          }

          const swaps = value.data?.onTokenEventsCreated.events
            .filter((e) => e.eventType === EventType.Swap)
            .sort((a, b) => a.timestamp - b.timestamp);
          swaps?.forEach((swap) => {
            if (swap.timestamp <= lastTimestamp.current) return;

            onUpdate({
              timestamp: swap.timestamp,
              price:
                swap.quoteToken === QuoteToken.Token0
                  ? Number(swap.token0PoolValueUsd ?? 0)
                  : Number(swap.token1PoolValueUsd ?? 0),
            });

            lastTimestamp.current = swap.timestamp;
          });
        },
        complete() {
          console.log("Price subscription completed");
        },
        error(err) {
          console.error(err);
          setError(String(err));
        },
      },
    );
  };

  useEffect(() => {
    fetchChartData().then(subscribeToChartData);
  }, [intervalSeconds]);

  return {
    tokenPrices,
    fetching,
    error,
  };
};
