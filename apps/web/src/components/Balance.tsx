import { PublicKey } from "@solana/web3.js";
import { useBalance } from "../hooks/useBalance";

export const Balance = ({ publicKey, inline }: { publicKey: PublicKey, inline?: boolean }) => {
  const { balance, loading } = useBalance({ publicKey });
  if (loading) return <div>...</div>;
  return <div className={inline ? "inline" : ""}>{balance}</div>;
};