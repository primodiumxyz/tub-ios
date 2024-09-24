import { useState, useEffect } from "react";
import { CoinDisplay } from "../components/CoinDisplay";


export const Coins = () => {
  const [coinId, setCoinId] = useState<string>("");

  useEffect(() => {
    const coinId = window.location.pathname.split("/")[2];
    setCoinId(coinId);
  }, []);

  return <CoinDisplay coinId={coinId} />;
};
