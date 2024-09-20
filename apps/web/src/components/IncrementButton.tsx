import { useWallet } from "@solana/wallet-adapter-react";
import { useServer } from "../hooks/useServer";

export default function IncrementButton() {
  const { publicKey } = useWallet();
  const { server, ready } = useServer();

  const onClick = async () => {
    if (!server || !ready) return;

    await server.incrementCall.mutate();
  };

  return (
    <button
      className="btn-primary"
      onClick={onClick}
      disabled={!publicKey || !ready}
    >
      {ready ? "Increment" : "Server not ready"}
    </button>
  );
}
