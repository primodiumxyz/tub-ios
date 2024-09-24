import { useEffect, useMemo, useState } from "react";
import { CoinDisplay } from "../components/CoinDisplay";
import { CoinData, generateRandomMemecoin } from "../utils/generateMemecoin";


export const Coins = () => {
  const [selectedCoin, setSelectedCoin] = useState<CoinData | null>(null);

  const gotoNext = () => {
    const randomIndex = Math.floor(Math.random() * coins.length);
    setSelectedCoin(coins[randomIndex]);
  };

  const coins = useMemo(() => {
    return Array.from({ length: 50 }, generateRandomMemecoin);
  }, []);

  useEffect(() => {
    if (coins.length > 0) {
      setSelectedCoin(coins[0]);
    }
  }, [coins]);

  if (selectedCoin) {
    return <CoinDisplay coinData={selectedCoin} gotoNext={gotoNext} />;
  }

  return <div className="flex flex-wrap justify-center">
    {coins.map((coin, index) => (
      <button 
        key={index} 
        onClick={() => setSelectedCoin(coin)} 
        className="px-4 py-2 m-1 bg-orange-300 rounded cursor-pointer"
      >
        {coin.name}
      </button>
    ))}
  </div>;
};
