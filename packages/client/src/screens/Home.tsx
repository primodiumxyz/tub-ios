import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { useWallet } from "@solana/wallet-adapter-react";
import CounterState from "../components/CounterState";
import IncrementButton from "../components/IncrementButton";

export const Home = () => {
  const { publicKey } = useWallet();

  if (!publicKey) {
    return (
      <div>
        Please connect a wallet.
        <CounterState />
        <WalletMultiButton />
      </div>
    );
  } else {
    return (
      <div>
        <p>Connected wallet: {publicKey.toString()}</p>
        <CounterState />
        <IncrementButton />
        <WalletMultiButton />
      </div>
    );
  }
};
