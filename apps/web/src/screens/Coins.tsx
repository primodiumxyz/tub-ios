import { useCallback, useEffect, useState } from "react";
import { CoinDisplay } from "../components/CoinDisplay";
import { CoinData } from "../utils/generateMemecoin";
import { useQuery } from "urql";
import { PublicKey } from "@solana/web3.js";
import { useGql } from "../hooks/useGql";


export const Coins = ({ publicKey }: { publicKey: PublicKey }) => {
  const { queries } = useGql();
  const [selectedCoin, setSelectedCoin] = useState<CoinData | null>(null);

  const [tokensQueryResult] = useQuery({ query: queries.GetAllTokensQuery });

  const gotoNext = useCallback(() => {
    if (!tokensQueryResult.data) return;
    const coins = tokensQueryResult.data.token;
    const randomIndex = Math.floor(Math.random() * coins.length);
    setSelectedCoin(coins[randomIndex]);
  }, [tokensQueryResult.data]);

  useEffect(() => {
    if (!tokensQueryResult.data) return;
    gotoNext();
  }, [gotoNext, tokensQueryResult.data]);

  if (tokensQueryResult.fetching) return <div>Loading...</div>;
  if (tokensQueryResult.error) return <div>Error: {tokensQueryResult.error.message}</div>;
  if (!publicKey) return <div>Please connect your wallet</div>;

  const coins = tokensQueryResult.data?.token ?? [];

  if (selectedCoin) {
    return (
      <CoinDisplay
        coinData={selectedCoin}
        publicKey={publicKey}
        gotoNext={gotoNext}
      />
    );
  }

  return (
    <div className="flex flex-wrap justify-center">
      {coins.map((coin, index) => (
        <button
          key={index}
          onClick={() => setSelectedCoin(coin)}
          className="px-4 py-2 m-1 bg-orange-300 rounded cursor-pointer"
        >
          {coin.name}
        </button>
      ))}
    </div>
  );
};
