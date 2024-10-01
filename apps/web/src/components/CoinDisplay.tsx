import { subscriptions } from "@tub/gql";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useReward } from "react-rewards";
import { useSubscription } from "urql";
import { PriceGraph } from "../components/PriceGraph"; // Import the new component
import { useServer } from "../hooks/useServer";
import { useSolBalance } from "../hooks/useSolBalance";
import { useTokenBalance } from "../hooks/useTokenBalance";
import { CoinData, lamportsToSol, solToLamports } from "../utils/generateMemecoin";
import { Price } from "./LamportDisplay";
import Slider from "./Slider";

const TIME_UNTIL_NEXT_TOKEN = 60;
const LEADING_PRICES_LENGTH = 5;

// https://stackoverflow.com/questions/8597731/are-there-known-techniques-to-generate-realistic-looking-fake-stock-data
const VOLATILITY = 0.2;
const PRECISION = 1e9;
const getRandomPriceChange = () => {
  const random = Math.random();
  let changePercent = random * VOLATILITY * 2;
  if (changePercent > VOLATILITY) changePercent -= 2 * VOLATILITY;
  return 1 + changePercent;
};

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
  const [timeUntilNextToken, setTimeUntilNextToken] = useState(0);

  /* --------------------------------- History -------------------------------- */
  const variables = useMemo(() => ({ tokenId: tokenData.id, since: new Date() }), [tokenData.id]);
  const [priceHistory] = useSubscription({
    query: subscriptions.GetTokenPriceHistorySinceSubscription,
    variables,
  });

  const tokenPrices = useMemo(() => {
    const history = priceHistory.data?.token_price_history ?? [];
    const formattedHistory = history
      .map((data) => ({
        timestamp: new Date(data.created_at).getTime() / 1000,
        price: BigInt(data.price),
      }))
      .sort((a, b) => a.timestamp - b.timestamp);
    return {
      loading: history.length === 0,
      current: BigInt(formattedHistory[history.length - 1]?.price ?? 0),
      history: formattedHistory,
    };
  }, [priceHistory]);

  // Additional leading data to simulate an initially pumping token (this is why it was displayed)
  const priceChanges = useMemo(
    () =>
      Array.from({ length: LEADING_PRICES_LENGTH }, () => {
        // Get 5 random decreasing price changes (we're generating the data in reverse)
        let change = getRandomPriceChange();
        do {
          change = getRandomPriceChange();
        } while (change > 1);
        return change;
      }),
    [],
  );
  const leadingTokenPricesHistory = useMemo(() => {
    if (tokenPrices.loading) return [];
    const firstData = tokenPrices.history[0];

    return (
      Object.values(
        priceChanges.reduce(
          (acc, priceChange, index) => {
            // Return the next data (effectively the previous data point)
            const price = (BigInt(acc[index]?.price) * BigInt(Math.floor(priceChange * PRECISION))) / BigInt(PRECISION);
            acc = [
              ...acc,
              {
                timestamp: Number(acc[index].timestamp) - 1,
                price,
              },
            ];

            return acc;
          },
          [
            {
              timestamp: firstData.timestamp,
              price: firstData.price,
            },
          ],
        ),
      )
        .sort((a, b) => a.timestamp - b.timestamp)
        // Remove the last item (since it's a duplicate of the first real data point)
        .slice(0, -1)
    );
  }, [tokenPrices, priceChanges]);

  const history = useMemo(
    () => [...leadingTokenPricesHistory, ...tokenPrices.history],
    [leadingTokenPricesHistory, tokenPrices.history],
  );

  useEffect(() => {
    const interval = setInterval(() => {
      // fetchPriceHistory();
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  /* ---------------------------------- Trade --------------------------------- */
  const [buyAmountSOL, setBuyAmountSOL] = useState(Math.min(10));
  const [amountBought, setAmountBought] = useState<number | null>(null);
  const [boughtPrice, setBoughtPrice] = useState<bigint | null>(null);
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

    const tokenPrice = tokenPrices.current ?? 1n;
    const amount = (1_000_000_000n * solToLamports(buyAmountSOL)) / tokenPrice;

    setBoughtPrice(tokenPrices.current);
    await server.buyToken.mutate({
      accountId: userId,
      tokenId: tokenData.id,
      amount: amount.toString(),
    });
    setBuyAmountSOL(0);
    setAmountBought(buyAmountSOL + (amountBought ?? 0));
  };

  const handleSell = useCallback(async () => {
    const sellAmountCoin = tokenBalance;
    if (sellAmountCoin <= 0) return;

    await server.sellToken.mutate({
      accountId: userId,
      tokenId: tokenData.id,
      amount: sellAmountCoin.toString(),
    });
    reward();

    setAmountBought(10);
    setTimeout(() => {
      gotoNext?.();
    }, 2000);
  }, [userId, tokenData.id, tokenBalance, server, reward, gotoNext]);

  const netWorthChange = SOLBalance - initialBalance;

  useEffect(() => {
    setTimeUntilNextToken(TIME_UNTIL_NEXT_TOKEN);
    setBoughtPrice(null);
  }, [tokenData.id]);

  // After some amount is bought, we can ride it for TIME_UNTIL_NEXT_TOKEN
  useEffect(() => {
    if (!amountBought) return;

    const interval = setInterval(() => {
      setTimeUntilNextToken((t) => t - 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [amountBought]);

  useEffect(() => {
    if (amountBought && timeUntilNextToken === 0) {
      handleSell();
    }
  }, [amountBought, timeUntilNextToken, handleSell]);

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
        {!tokenPrices.loading && (
          <p className="text-2xl font-bold">
            <Price lamports={tokenPrices.current} /> SOL
          </p>
        )}
        {tokenPrices.loading && <p className="text-2xl font-bold">Loading...</p>}
      </div>
      <div className="flex flex-col">
        <PriceGraph
          prices={history.slice(-20)}
          refPrice={history[LEADING_PRICES_LENGTH]?.price}
          boughtPrice={boughtPrice}
          timeUntilNextToken={timeUntilNextToken}
        />
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
                  <Price lamports={(tokenBalance * tokenPrices.current) / 1_000_000_000n} /> SOL
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
            loading={tokenPrices.loading}
          />
        </div>
        <button
          onClick={() => {
            if (amountBought) {
              handleSell();
            } else {
              gotoNext?.();
            }
          }}
          className="mt-4 p-3 disabled:opacity-50"
          disabled={tokenPrices.loading}
        >
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
  loading,
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
  loading: boolean;
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

  const change = (coinBalance * currentPrice) / 1_000_000_000n - solToLamports(amountBought);

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
          {!loading && (
            <p className="text-xs opacity-50 w-full text-right mb-2 ">
              ({(buyAmountSOL / Number(lamportsToSol(currentPrice))).toFixed(4)} {tokenData?.symbol.toUpperCase()})
            </p>
          )}
          {loading && <p className="text-xs opacity-50 w-full text-right mb-2 ">...</p>}

          <Slider onSlideComplete={handlePressBuy} disabled={buyAmountSOL <= 0 || loading} text="> > > >" />
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
              <Price className="ml-1" lamports={change} /> SOL
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
