import { useState, useEffect, useCallback } from "react";
import { PriceGraph } from "../components/PriceGraph"; // Import the new component
import { CoinData } from "../utils/generateMemecoin";
import { useReward } from "react-rewards";

type Price = {
  timestamp: number;
  price: number;
};

export const CoinDisplay = ({
  coinData,
  gotoNext,
}: {
  coinData: CoinData;
  gotoNext?: () => void;
}) => {
  // todo: fetch coin data from server
  const [balance, setBalance] = useState(1000); // User's initial balance
  const [coinBalance, setCoinBalance] = useState(0); // User's coin balance

  const [buyAmountUSD, setBuyAmountUSD] = useState(Math.min(balance * 0.1, 10));
  const [amountBought, setAmountBought] = useState<number | null>(null);

  const generatePrice = useCallback((lastPrice: number, timestamp?: number) => {
    const change = lastPrice * (Math.random() * 0.48 - 0.24); // 10% chance to generate a random change between -24% and 24%
    return {
      timestamp: timestamp || Date.now(),
      price: Math.max(0, lastPrice + change), // Ensure price doesn't go below 0
    };
  }, []);

  useEffect(() => {
    setCoinBalance(0);
    setPrices([]);
  }, [coinData]);

  const [prices, setPrices] = useState<Price[]>([]);

  useEffect(() => {
    if (prices.length == 0) {
      generatePrice(50);
    }
    const intervalId = setInterval(() => {
      const newPrice =
        prices.length > 0
          ? generatePrice(prices[prices.length - 1].price)
          : generatePrice(50);
      setPrices((prevPrices) => [...prevPrices, newPrice]);
    }, 1000); // 1000 milliseconds = 1 second
    return () => clearInterval(intervalId);
  }, [generatePrice, prices]);

  const { reward } = useReward("rewardId", "confetti");

  const handleBuy = () => {
    const currentPrice = prices[prices.length - 1]?.price || 0;
    const tokenAmount = buyAmountUSD / currentPrice;
    if (buyAmountUSD <= 0) {
      alert("Please enter a valid amount to buy");
      return;
    }
    if (buyAmountUSD > balance) {
      alert("Insufficient balance to buy coins");
      return;
    }
    setBalance(balance - buyAmountUSD);
    setCoinBalance(coinBalance + tokenAmount);
    setBuyAmountUSD(0);
    setAmountBought(buyAmountUSD + (amountBought ?? 0));
  };

  const handleSell = () => {
    const currentPrice = prices[prices.length - 1]?.price || 0;
    const sellAmountCoin = coinBalance;

    if (sellAmountCoin <= 0) {
      alert("Please enter a valid amount to sell");
      return;
    }
    if (sellAmountCoin > coinBalance) {
      alert("Insufficient coins to sell");
      return;
    }
    reward();

    setBalance(balance + sellAmountCoin * currentPrice);
    setCoinBalance(coinBalance - sellAmountCoin);
    setAmountBought(10);
  };

  const currentPrice = prices[prices.length - 1]?.price || 0;
  const netWorthChange = balance - 1000;

  return (
    <div className="relative text-white">
      <div className="mb-4">
        <p className="text-sm opacity-50">Your Net Worth</p>
        <p className="text-3xl font-bold">${balance.toFixed(2)}</p>
        {netWorthChange !== 0 && (
          <p>
            {netWorthChange > 0
              ? `+$${netWorthChange.toFixed(2)}`
              : `-$${Math.abs(netWorthChange).toFixed(2)}`}
            <span
              className={`inline-block ml-1 ${
                netWorthChange > 0 ? "text-green-500" : "text-red-500"
              }`}
            >
              {netWorthChange > 0 ? "▲" : "▼"}
            </span>
            <span className="ml-1">
              {((Math.abs(netWorthChange) / 1000) * 100).toFixed(2)}%
            </span>
          </p>
        )}
      </div>
      <div>
        <p className="flex flex-row gap-2 items-center">
          <img
            className="w-4 h-4 inline"
            src="https://imgs.search.brave.com/K6CRsHMIBDDXbta9YUjY9_Ov9jCCiZVc55qze-tALN4/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93YWxs/cGFwZXJjYXZlLmNv/bS93cC93cDEwNDIw/MDQ1LmpwZw"
          />
          <span className="text-base inline">
            {coinData?.name} (${coinData?.symbol.toUpperCase()})
          </span>
        </p>
        <p className="text-2xl font-bold">
          ${prices[prices.length - 1]?.price.toFixed(3)}
        </p>
      </div>
      <div className="flex flex-col">
        <PriceGraph prices={prices} /> {/* Use the new component */}
        <div className="flex flex-col w-full">
          <div className="mt-6">
            <p className="text-sm opacity-50">
              Your ${coinData?.symbol.toUpperCase()} Balance
            </p>
            <h2 className="text-xl font-semibold">
              <span className="font-bold text-lg">
                {coinBalance.toFixed(3)} ${coinData?.symbol.toUpperCase()}
              </span>
            </h2>
          </div>

          <BuySellForm
            coinData={coinData}
            buyAmountUSD={buyAmountUSD}
            setBuyAmountUSD={setBuyAmountUSD}
            handleBuy={handleBuy}
            handleSell={handleSell}
            currentPrice={currentPrice}
            balance={balance}
            coinBalance={coinBalance}
          />
        </div>
        <button onClick={gotoNext} className="mt-4 p-3">
          <p className="text-sm font-bold text-yellow-300"> Next token</p>
        </button>
      </div>
    </div>
  );
};

const BuySellForm = ({
  coinData,
  buyAmountUSD,
  setBuyAmountUSD,
  handleBuy,
  handleSell,
  currentPrice,
  balance,
  coinBalance,
}: {
  coinData: CoinData;
  buyAmountUSD: number;
  setBuyAmountUSD: (amount: number) => void;
  handleBuy: () => void;
  handleSell: () => void;
  currentPrice: number;
  balance: number;
  coinBalance: number;
}) => {
  const [activeTab, setActiveTab] = useState<"buy" | "sell">("buy");
  const handleMaxBuy = () => {
    setBuyAmountUSD(Math.floor(balance * 100) / 100);
  };

  const handlePressBuy = () => {
    handleBuy();
    setActiveTab("sell");
  };

  const handlePressSell = () => {
    handleSell();
    setActiveTab("buy");
  };

  return (
    <div className="mt-6">
      <div className="flex">
        <button
          className={`py-2 px-6 text-lg rounded-t-2xl ${
            activeTab === "buy" ? "bg-white/50" : "bg-white/30"
          }`}
          onClick={() => setActiveTab("buy")}
        >
          Buy
        </button>
        <button
          className={`py-2 px-6 text-lg rounded-t-2xl ${
            activeTab === "sell" ? "bg-white/60" : "bg-white/30"
          }`}
          onClick={() => setActiveTab("sell")}
        >
          Sell
        </button>
      </div>
      <div className="p-8 relative bg-white/50 rounded-b-3xl rounded-r-3xl">
        <span
          className="absolute top-1/2 right-1/2 transform -translate-y-1/2 -translate-x-1/2"
          id="rewardId"
        />
        {activeTab === "buy" ? (
          <div>
            <div className="flex justify-between items-center mb-2">
              <input
                type="range"
                min="0"
                max={balance}
                step="0.01"
                value={buyAmountUSD}
                onChange={(e) => setBuyAmountUSD(Number(e.target.value))}
                className="w-full mr-2"
              />
              <button
                onClick={handleMaxBuy}
                className="bg-blue-500 text-white py-1 px-2 rounded"
              >
                Max
              </button>
            </div>
            <p>
              <span className="font-bold text-lg">
                ${buyAmountUSD.toFixed(2)}
              </span>{" "}
              ({(buyAmountUSD / currentPrice).toFixed(2)}{" "}
              {coinData?.symbol.toUpperCase()})
            </p>
            <button
              onClick={handlePressBuy}
              className="mt-2 w-full bg-blue-500 text-white py-2 px-4 rounded disabled:opacity-50"
              disabled={buyAmountUSD <= 0 || buyAmountUSD > balance}
            >
              BUY!
            </button>
          </div>
        ) : (
          <div>
            <div className="flex flex-col items-center">
              <p>
                <span className="font-bold text-lg">
                  ${(coinBalance * currentPrice).toFixed(2)}
                </span>{" "}
                ({coinBalance.toFixed(3)} {coinData?.symbol.toUpperCase()})
              </p>
              <button
                onClick={handlePressSell}
                className="mt-2 w-full bg-red-500 text-white py-2 px-4 rounded disabled:opacity-50"
                disabled={coinBalance <= 0}
              >
                SELL!
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
