import { useEffect, useState } from "react";

import { formatLargeNumber } from "@/lib/utils";

const REFRESH_INTERVAL = 10_000;

export const useSolPrice = () => {
  const [price, setPrice] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const solToUsd = (solAmount: number) => {
    if (!price) return "0";
    const usdPrice = solAmount * price;
    if (usdPrice > 1) return `$${formatLargeNumber(usdPrice)}`;
    return `$${Number(usdPrice.toFixed(6))}`;
  };

  useEffect(() => {
    const fetchPrice = async () => {
      try {
        const response = await fetch("https://min-api.cryptocompare.com/data/price?fsym=SOL&tsyms=USD");
        const data = await response.json();
        setPrice(data.USD);
        setError(null);
      } catch (err) {
        setError("Failed to fetch SOL price");
        console.error("Error fetching SOL price:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchPrice();

    const interval = setInterval(fetchPrice, REFRESH_INTERVAL);
    return () => clearInterval(interval);
  }, []);

  return { price, error, loading, solToUsd };
};
