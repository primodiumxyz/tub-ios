import { PublicKey } from "@solana/web3.js";
import { useSolBalance } from "../hooks/useSolBalance";

export const Balance = ({
  publicKey,
  inline,
}: {
  publicKey: PublicKey;
  inline?: boolean;
}) => {
  const { balance, loading } = useSolBalance({ publicKey });
  if (loading) return <div>...</div>;
  return <div className={inline ? "inline" : ""}>{balance}</div>;
};
