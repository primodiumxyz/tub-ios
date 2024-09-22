import { useWallet } from "@solana/wallet-adapter-react";
import { useServer } from "../hooks/useServer";
import { useState } from "react";

export default function IncrementButton() {
  const { publicKey } = useWallet();
  const { server, ready } = useServer();
  const [isLoading, setIsLoading] = useState(false);

  const onClick = async () => {
    if (!server || !ready) return;

    setIsLoading(true);
    await server.incrementCall.mutate();
    setIsLoading(false);
  };

  return (
    <button
      className="btn-primary"
      onClick={onClick}
      disabled={!publicKey || !ready || isLoading}
    >
      {isLoading || !ready ? "Loading..." : "Increment"}
    </button>
  );
}
