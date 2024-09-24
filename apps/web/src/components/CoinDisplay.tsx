import { useState, useEffect, useCallback } from "react";
import { PriceGraph } from "../components/PriceGraph"; // Import the new component
import { CoinData } from "../utils/generateMemecoin";

type Price = {
  timestamp: number;
  price: number;
};

export const CoinDisplay = ({ coinData, clearSelectedCoin }: { coinData: CoinData, clearSelectedCoin: () => void }) => {
  // todo: fetch coin data from server
  const [balance, setBalance] = useState(1000); // User's initial balance
  const [coinBalance, setCoinBalance] = useState(0); // User's coin balance


  const [buyAmount, setBuyAmount] = useState(0);
  const [sellAmount, setSellAmount] = useState(0);

    const generatePrice = useCallback((lastPrice: number, timestamp?: number) => {
      const change = lastPrice * (Math.random() * 0.48 - 0.24); // 10% chance to generate a random change between -24% and 24%
      return {
        timestamp: timestamp || Date.now(),
        price: Math.max(0, lastPrice + change), // Ensure price doesn't go below 0
      };
    }, []);

  const [prices, setPrices] = useState<Price[]>([]);


  useEffect(() => {
    const intervalId = setInterval(() => {
        const newPrice = prices.length > 0 ? generatePrice(prices[prices.length - 1].price) : generatePrice(50);
        setPrices((prevPrices) => [...prevPrices, newPrice]);
    }, 1000); // 1000 milliseconds = 1 second
    return () => clearInterval(intervalId);
  }, [generatePrice, prices]);

  const handleBuy = () => {
    const currentPrice = prices[prices.length - 1]?.price || 0;
    const cost = buyAmount * currentPrice;
    // {{ edit_1 }}
    if (buyAmount <= 0) {
      alert("Please enter a valid amount to buy");
      return;
    }
    if (cost > balance) {
      alert("Insufficient balance to buy coins");
      return;
    }
    setBalance(balance - cost);
    setCoinBalance(coinBalance + buyAmount);
    setBuyAmount(0);
  };

  const handleSell = () => {
    const currentPrice = prices[prices.length - 1]?.price || 0;
    const revenue = sellAmount * currentPrice;
    // {{ edit_2 }}
    if (sellAmount <= 0) {
      alert("Please enter a valid amount to sell");
      return;
    }
    if (sellAmount > coinBalance) {
      alert("Insufficient coins to sell");
      return;
    }
    setBalance(balance + revenue);
    setCoinBalance(coinBalance - sellAmount);
    setSellAmount(0);
  };

  const currentPrice = prices[prices.length - 1]?.price || 0;

  return (
    <div className="relative">
      <button onClick={clearSelectedCoin} className="absolute top-0 right-0 text-sm text-gray-500 bg-orange-300 rounded-full px-2 py-1">GO BACK</button>
      <h1 className="text-2xl font-bold mb-4">{coinData?.name}</h1>
      <div className="flex flex-row gap-10">
        <PriceGraph prices={prices} /> {/* Use the new component */}
        <div className="flex flex-col w-full">
          <div className="mt-6">
            <h2 className="text-xl font-semibold">
              Current Price: ${currentPrice.toFixed(2)}
            </h2>
            <h2 className="text-xl font-semibold">
              Balance: ${balance.toFixed(2)}
            </h2>
            <h2 className="text-xl font-semibold">
              {coinData?.name}: {coinBalance} {coinData?.symbol}
            </h2>
          </div>
          <div className="mt-6 bg-white p-4 rounded-lg shadow">
            <h2 className="text-lg font-semibold">Buy Coins</h2>
            <input
              type="range"
              min="0"
              max="100"
              step="0.1"
              value={buyAmount}
              onChange={(e) => setBuyAmount(Number(e.target.value))}
              className="w-full"
            />
            <p>
              Value of {buyAmount} coins: $
              {(buyAmount * currentPrice).toFixed(2)}
            </p>{" "}
            {/* Display value of coins to buy */}
            <button
              onClick={handleBuy}
              className="mt-2 bg-blue-500 text-white py-2 px-4 rounded disabled:opacity-50"
              disabled={buyAmount <= 0 || buyAmount > balance / currentPrice}
            >
              Confirm Buy
            </button>
          </div>
          <div className="mt-6 bg-white p-4 rounded-lg shadow w-full">
            <h2 className="text-lg font-semibold">Sell Coins</h2>
            <input
              type="range"
              min="0"
              max="100"
              step="0.1"
              value={sellAmount}
              onChange={(e) => setSellAmount(Number(e.target.value))}
              className="w-full"
            />
            <p>
              Value of {sellAmount} coins: $
              {(sellAmount * currentPrice).toFixed(2)}
            </p>{" "}
            {/* Display value of coins to sell */}
            <button
              onClick={handleSell}
              className="mt-2 bg-red-500 text-white py-2 px-4 rounded disabled:opacity-50"
              disabled={sellAmount <= 0 || sellAmount > coinBalance}
            >
              Confirm Sell
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
