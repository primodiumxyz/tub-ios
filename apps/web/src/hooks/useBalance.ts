import { useConnection } from "@solana/wallet-adapter-react";
import { LAMPORTS_PER_SOL, PublicKey } from "@solana/web3.js";
import { useCallback, useEffect, useState } from "react";

export const useBalance = ({publicKey}: {publicKey: PublicKey}) => {
  const { connection } = useConnection();
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);    

  useEffect(() => {
    fetchBalance();

    const interval = setInterval(fetchBalance, 1000);
    return () => clearInterval(interval);
  }, [connection, publicKey]);
  
  const fetchBalance = useCallback(async () => {
  if (publicKey) {
    try {
      const balance = await connection.getBalance(publicKey);
      setBalance(balance / LAMPORTS_PER_SOL);
      setLoading(false);
    } catch (error) {
      console.error("Error fetching balance:", error);
      }
    }
  }, [publicKey, connection]);

  return { balance, loading };
};