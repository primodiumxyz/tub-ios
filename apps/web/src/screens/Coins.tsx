import { useCallback, useEffect, useState } from "react";
import { CoinDisplay } from "../components/CoinDisplay";
import { CoinData } from "../utils/generateMemecoin";
import { queries } from "@tub/gql";
import { useQuery } from "urql";
import { PublicKey } from "@solana/web3.js";

export const Coins = ({ publicKey }: { publicKey: PublicKey }) => {
  const [selectedCoin, setSelectedCoin] = useState<CoinData | null>(null);

  const [result] = useQuery({ query: queries.GetAllTokensQuery });

  const gotoNext = useCallback(() => {
    if (!result.data) return;
    const coins = result.data.token;
    const randomIndex = Math.floor(Math.random() * coins.length);
    setSelectedCoin(coins[randomIndex]);
  }, [result.data]);

  useEffect(() => {
    if (!result.data) return;
    gotoNext();
  }, [gotoNext, result.data]);

  if (result.fetching) return <div>Loading...</div>;
  if (result.error) return <div>Error: {result.error.message}</div>;
  if (!publicKey) return <div>Please connect your wallet</div>;

  const coins = result.data?.token ?? [];

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
