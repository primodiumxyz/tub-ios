import { useEffect, useState } from "react";
import { PriceGraph } from "../components/PriceGraph"; // Import the new component
import { CoinData } from "../utils/generateMemecoin";
import { useReward } from "react-rewards";
import Slider from "./Slider";
import { PublicKey } from "@solana/web3.js";
import { useTokenBalance } from "../hooks/useTokenBalance";
import { useSolBalance } from "../hooks/useSolBalance";
import { useQuery } from "urql";
import { useServer } from "../hooks/useServer";
import { queries } from "@tub/gql";

type Price = {
  timestamp: number;
  price: number;
};

export const CoinDisplay = ({
  publicKey,
  coinData,
  gotoNext,
}: {
  coinData: CoinData;
  publicKey: PublicKey;
  gotoNext?: () => void;
}) => {
  const { balance: solBalance } = useSolBalance({ publicKey });
  const { balance: coinBalance } = useTokenBalance({
    publicKey,
    tokenId: coinData.id,
  });
  const server = useServer();

  const [prices, setPrices] = useState<Price[]>([]);

  const [priceHistory] = useQuery({
    query: queries.GetTokenPriceHistorySinceQuery,
    variables: { tokenId: coinData.id, since: new Date() },
  });

  const [fetchedInitialPrices, setFetchedInitialPrices] = useState(false);

  useEffect(() => {
    if (!priceHistory.data || fetchedInitialPrices) return;
      const prices = priceHistory.data.token_price_history.map((price) => ({
        timestamp: price.created_at.getTime() / 1000,
        price: Number(price.price),
      }));
      setPrices(prices);
      setFetchedInitialPrices(true);
  }, [priceHistory.data, fetchedInitialPrices]);

  const [price, refetchPrice] = useQuery({
    query: queries.GetLatestTokenPriceQuery,
    variables: { tokenId: coinData.id },
  });

  useEffect(() => {
    if (!fetchedInitialPrices) return;
    refetchPrice();
    const interval = setInterval(() => {
      refetchPrice();
    }, 1000);
    return () => clearInterval(interval);
  }, [refetchPrice, fetchedInitialPrices]);

  useEffect(() => {
    if (!fetchedInitialPrices) return;
    const currPrice = price.data?.token_price_history[0].price;
    if (currPrice === undefined) return;
    setPrices(prevPrices => [
      ...prevPrices,
      { timestamp: Date.now() / 1000, price: Number(currPrice) },
    ]);
  }, [price, fetchedInitialPrices]);

  const [buyAmountUSD, setBuyAmountUSD] = useState(
    Math.min(solBalance * 0.1, 10)
  );
  const [amountBought, setAmountBought] = useState<number | null>(null);

  const { reward } = useReward("rewardId", "confetti");

  const handleBuy = () => {
    if (buyAmountUSD <= 0) {
      alert("Please enter a valid amount to buy");
      return;
    }
    if (buyAmountUSD > solBalance) {
      alert("Insufficient balance to buy coins");
      return;
    }
    setBuyAmountUSD(0);
    setAmountBought(buyAmountUSD + (amountBought ?? 0));
  };

  const handleSell = () => {
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

    setAmountBought(10);
  };

  const currentPrice = prices[prices.length - 1]?.price || 0;
  const netWorthChange = solBalance - 1000;

  return (
    <div className="relative text-white">
      <div className="mb-4">
        <p className="text-sm opacity-50">Your Net Worth</p>
        <p className="text-3xl font-bold">${solBalance.toFixed(2)}</p>
        <button onClick={() => {
            server.airdropNativeToUser.mutate({accountId: publicKey.toBase58(), amount: "1000000000"});
        }}>
          Refetch Price History
        </button>
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
            balance={solBalance}
            coinBalance={coinBalance}
            amountBought={amountBought ?? 0}
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
  amountBought,
  balance,
  coinBalance,
}: {
  coinData: CoinData;
  buyAmountUSD: number;
  setBuyAmountUSD: (amount: number) => void;
  handleBuy: () => void;
  handleSell: () => void;
  currentPrice: number;
  amountBought: number;
  balance: number;
  coinBalance: number;
}) => {
  const [activeTab, setActiveTab] = useState<"buy" | "sell">("buy");

  const handlePressBuy = () => {
    handleBuy();
    setActiveTab("sell");
  };

  const handlePressSell = () => {
    handleSell();
    setActiveTab("buy");
  };

  const change = coinBalance * currentPrice - amountBought;
  return (
    <div className="mt-6 relative">
      <span
        className="absolute top-1/2 right-1/2 transform -translate-y-1/2 -translate-x-1/2"
        id="rewardId"
      />
      {activeTab === "buy" ? (
        <div className="p-8 relative bg-white/50 rounded-3xl">
          <div className="flex justify-between items-center">
            <input
              type="range"
              min="0"
              max={balance}
              step="1"
              value={buyAmountUSD}
              onChange={(e) => setBuyAmountUSD(Number(e.target.value))}
              className="w-full mr-2"
            />
            <div className="flex flex-col text-right w-fit">
              <p className="font-bold text-2xl">${buyAmountUSD}</p>
            </div>
          </div>
          <p className="text-xs opacity-50 w-full text-right mb-2 ">
            ({(buyAmountUSD / currentPrice).toFixed(2)}{" "}
            {coinData?.symbol.toUpperCase()})
          </p>

          <Slider
            onSlideComplete={handlePressBuy}
            disabled={buyAmountUSD <= 0}
            text="> > > >"
          />
        </div>
      ) : (
        <div>
          <div className="flex flex-col items-center">
            <button
              onClick={handlePressSell}
              className="mt-2 w-20 h-20 rounded-full text-black bg-white/50 disabled:opacity-50"
              disabled={coinBalance <= 0}
            >
              SELL
            </button>
            <div>
              <span
                className={`inline-block ml-1 ${
                  change > 0 ? "text-green-500" : "text-red-500"
                }`}
              >
                {change > 0 ? "▲" : "▼"}
              </span>
              <span className="ml-1">${Math.abs(change).toFixed(2)}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
