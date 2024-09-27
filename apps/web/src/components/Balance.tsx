import { useSolBalance } from "../hooks/useSolBalance";
import { Price } from "./LamportDisplay";

export const Balance = ({ userId, inline }: { userId: string; inline?: boolean }) => {
  const { balance, loading } = useSolBalance({ userId });
  if (loading) return <div>...</div>;
  return (
    <div className={inline ? "inline" : ""}>
      <Price lamports={balance} /> SOL
    </div>
  );
};
