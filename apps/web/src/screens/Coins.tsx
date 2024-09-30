import { useCallback, useEffect, useRef, useState } from "react";
import { CoinDisplay } from "../components/CoinDisplay";
import { useServer } from "../hooks/useServer";
import { CoinData, COINS, getRandomCoin } from "../utils/generateMemecoin";

export const Coins = ({ userId }: { userId: string }) => {
  const server = useServer();
  const tokenData = useRef<(CoinData & { id: string }) | undefined>(undefined);
  const [fetching, setFetching] = useState(true);
  const [error, setError] = useState(false);

  const requestToken = useCallback(async (index?: number) => {
    setFetching(true);
    setError(false);

    const data = getRandomCoin(index);
    const res = await server.registerNewToken.mutate(data);
    if (res?.insert_token_one?.id) {
      tokenData.current = { ...data, id: res.insert_token_one.id };
    } else {
      setError(true);
    }

    setFetching(false);
  }, []);

  useEffect(() => {
    requestToken();
  }, [requestToken]);

  if (fetching) return <div className="text-white">Loading...</div>;
  if (error) return <div className="text-white">Error: failed to register new token</div>;
  if (tokenData.current)
    return <CoinDisplay tokenData={tokenData.current} userId={userId} gotoNext={() => requestToken()} />;

  return (
    <div className="flex flex-wrap justify-center">
      {COINS.map((coin, index) => (
        <button
          key={index}
          onClick={() => requestToken(index)}
          className="px-4 py-2 m-1 bg-orange-300 rounded cursor-pointer"
        >
          {coin.name}
        </button>
      ))}
    </div>
  );
};
