import { useMemo, useState } from "react";
import { CoinDisplay } from "../components/CoinDisplay";
import { CoinData, generateRandomMemecoin } from "../utils/generateMemecoin";


export const Coins = () => {
  const [selectedCoin, setSelectedCoin] = useState<CoinData | null>(null);

  const clearSelectedCoin = () => {
    setSelectedCoin(null);
  };

  const coins = useMemo(() => {
    return Array.from({ length: 50 }, generateRandomMemecoin);
  }, []);

  if (selectedCoin) {
    return <CoinDisplay coinData={selectedCoin} clearSelectedCoin={clearSelectedCoin} />;
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
