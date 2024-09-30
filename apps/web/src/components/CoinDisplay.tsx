import { subscriptions } from "@tub/gql";
import { useMemo, useState } from "react";
import { useReward } from "react-rewards";
import { useSubscription } from "urql";
import { PriceGraph } from "../components/PriceGraph"; // Import the new component
import { useServer } from "../hooks/useServer";
import { useSolBalance } from "../hooks/useSolBalance";
import { useTokenBalance } from "../hooks/useTokenBalance";
import { CoinData, lamportsToSol, solToLamports } from "../utils/generateMemecoin";
import { Price } from "./LamportDisplay";
import Slider from "./Slider";

export const CoinDisplay = ({
  tokenData,
  userId,
  gotoNext,
}: {
  tokenData: CoinData & { id: string };
  userId: string;
  gotoNext?: () => void;
}) => {
  const { balance: SOLBalance, initialBalance } = useSolBalance({ userId });
  const { balance: tokenBalance } = useTokenBalance({
    userId,
    tokenId: tokenData.id,
  });
  const server = useServer();

  /* --------------------------------- History -------------------------------- */
  const variables = useMemo(() => ({ tokenId: tokenData.id, since: new Date() }), [tokenData.id]);
  const [priceHistory] = useSubscription({
    query: subscriptions.GetTokenPriceHistorySinceSubscription,
    variables,
  });

  const tokenPrices = useMemo(() => {
    const history = priceHistory.data?.token_price_history ?? [];
    return {
      fetched: history.length > 0,
      current: BigInt(history[history.length - 1]?.price ?? 0),
      history: history
        .map((data) => ({
          timestamp: new Date(data.created_at).getTime() / 1000,
          price: BigInt(data.price),
        }))
        .reverse(),
    };
  }, [priceHistory]);

  /* ---------------------------------- Trade --------------------------------- */
  const [buyAmountSOL, setBuyAmountSOL] = useState(Math.min(10));
  const [amountBought, setAmountBought] = useState<number | null>(null);
  const { reward } = useReward("rewardId", "confetti");

  const handleBuy = async () => {
    if (buyAmountSOL <= 0) {
      alert("Please enter a valid amount to buy");
      return;
    }
    if (buyAmountSOL > SOLBalance) {
      alert("Insufficient balance to buy coins");
      return;
    }

    const amount = (1_000_000_000n * solToLamports(buyAmountSOL)) / (tokenPrices.current ?? 1n);

    await server.buyToken.mutate({
      accountId: userId,
      tokenId: tokenData.id,
      amount: amount.toString(),
    });
    setBuyAmountSOL(0);
    setAmountBought(buyAmountSOL + (amountBought ?? 0));
  };

  const handleSell = async () => {
    const sellAmountCoin = tokenBalance;

    if (sellAmountCoin <= 0) {
      alert("Please enter a valid amount to sell");
      return;
    }
    if (sellAmountCoin > tokenBalance) {
      alert("Insufficient coins to sell");
      return;
    }

    await server.sellToken.mutate({
      accountId: userId,
      tokenId: tokenData.id,
      amount: sellAmountCoin.toString(),
    });
    reward();

    setAmountBought(10);
  };

  const netWorthChange = SOLBalance - initialBalance;

  return (
    <div className="relative text-white">
      <div className="mb-4">
        <p className="text-sm opacity-50">Your Net Worth</p>
        <div className="flex flex-row gap-2 items-center">
          <p className="text-3xl font-bold">
            <Price lamports={SOLBalance} /> SOL
          </p>
          {SOLBalance < 10000000n && (
            <button
              onClick={() => {
                if (!userId) {
                  alert("Please register to receive airdrops");
                  return;
                }
                server.airdropNativeToUser.mutate({
                  accountId: userId,
                  amount: solToLamports(100).toString(),
                });
              }}
              className="text-sm bg-white/50 text-black p-2 rounded-md"
            >
              Airdrop
            </button>
          )}
        </div>
        {netWorthChange === 69n && (
          <p>
            {netWorthChange > 0 ? `+` : `-`} <Price lamports={netWorthChange} />
            <span className={`inline-block ml-1 ${netWorthChange > 0 ? "text-green-500" : "text-red-500"}`}>
              {netWorthChange > 0 ? "▲" : "▼"}
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
            {tokenData.name} (${tokenData.symbol.toUpperCase()})
          </span>
        </p>
        {tokenPrices.fetched && (
          <p className="text-2xl font-bold">
            <Price lamports={tokenPrices.current} /> SOL
          </p>
        )}
        {!tokenPrices.fetched && <p className="text-2xl font-bold">Loading...</p>}
      </div>
      <div className="flex flex-col">
        <PriceGraph prices={tokenPrices.history} /> {/* Use the new component */}
        <div className="flex flex-col w-full">
          <div className="mt-6">
            <p className="text-sm opacity-50">Your {tokenData?.symbol.toUpperCase()} Balance</p>
            <h2 className="text-xl font-semibold">
              <div className="font-bold text-lg flex flex-col">
                <p>
                  {" "}
                  <Price lamports={tokenBalance} /> {tokenData?.symbol.toUpperCase()}
                </p>
                <p className="text-sm opacity-50">
                  {" "}
                  <Price lamports={tokenBalance * tokenPrices.current} /> SOL
                </p>
              </div>
            </h2>
          </div>

          <BuySellForm
            tokenData={tokenData}
            buyAmountSOL={buyAmountSOL}
            setBuyAmountSOL={setBuyAmountSOL}
            handleBuy={handleBuy}
            handleSell={handleSell}
            currentPrice={tokenPrices.current}
            balance={SOLBalance}
            coinBalance={tokenBalance}
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
  tokenData,
  buyAmountSOL,
  setBuyAmountSOL,
  handleBuy,
  handleSell,
  currentPrice,
  amountBought,
  balance,
  coinBalance,
}: {
  tokenData: CoinData;
  buyAmountSOL: number;
  setBuyAmountSOL: (amount: number) => void;
  handleBuy: () => void;
  handleSell: () => void;
  currentPrice: bigint;
  amountBought: number;
  balance: bigint;
  coinBalance: bigint;
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

  const change = coinBalance * currentPrice - solToLamports(amountBought);
  return (
    <div className="mt-6 relative">
      <span className="absolute top-1/2 right-1/2 transform -translate-y-1/2 -translate-x-1/2" id="rewardId" />
      {activeTab === "buy" ? (
        <div className="p-8 relative bg-white/50 rounded-3xl">
          <div className="flex justify-between items-center">
            <input
              type="range"
              min="0"
              max={lamportsToSol(balance)}
              step="1"
              value={buyAmountSOL}
              onChange={(e) => setBuyAmountSOL(Number(e.target.value))}
              className="w-1/2 mr-2"
            />
            <span className="font-bold text-2xl inline text-right">{buyAmountSOL} SOL</span>
          </div>
          <p className="text-xs opacity-50 w-full text-right mb-2 ">
            ({buyAmountSOL / Number(lamportsToSol(currentPrice))} {tokenData?.symbol.toUpperCase()})
          </p>

          <Slider onSlideComplete={handlePressBuy} disabled={buyAmountSOL <= 0} text="> > > >" />
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
              <span className={`inline-block ml-1 ${change > 0 ? "text-green-500" : "text-red-500"}`}>
                {change > 0 ? "▲" : "▼"}
              </span>
              <span className="ml-1">{lamportsToSol(change)} SOL</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
