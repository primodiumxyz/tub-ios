import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { useWallet } from "@solana/wallet-adapter-react";
import CounterState from "../components/CounterState";
import IncrementButton from "../components/IncrementButton";
import { CoreProvider } from "../providers/CoreProvider";
import TokenAccountsList from "../components/TokenAccountsList";
import CreateTokenForm from "../components/CreateTokenForm";

export const Home = () => {
  const { publicKey, wallet } = useWallet();

  if (!wallet || !publicKey) {
    return (
      <div>
        Please connect a wallet.
        <WalletMultiButton />
      </div>
    );
  } else {
    return (
      <CoreProvider wallet={wallet} publicKey={publicKey}>
        <div>
          <div style={{ display: "flex", flexDirection: "row" }}>
            <p>Connected wallet: {publicKey.toString()}</p>
            <WalletMultiButton />
          </div>
          <hr />
          <div style={{ display: "flex", flexDirection: "row", gap: "10px" }}>
            <IncrementButton />
            <CounterState />
          </div>
          <hr />
          <CreateTokenForm />
          <TokenAccountsList />
        </div>
      </CoreProvider>
    );
  }
};
