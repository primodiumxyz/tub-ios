import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { useWallet } from "@solana/wallet-adapter-react";
import CounterState from "../components/CounterState";
import IncrementButton from "../components/IncrementButton";
import { CoreProvider } from "../providers/CoreProvider";
import CreateTokenForm from "../components/CreateTokenForm";
import TokenAccountsList from "../components/TokenAccountsList";

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
        <div className="w-full h-full flex flex-col items-center justify-center">
          <div className="flex flex-col items-center w-[350px] p-2 gap-2">
            <div className="absolute top-2 right-2">
              <WalletMultiButton />
            </div>
            <hr />
            <div className="w-[350px] shadow-md flex flex-row justify-center gap-10 items-center bg-slate-300 rounded-xl p-2">
              <IncrementButton />
              <CounterState />
            </div>
            <hr />
            <div className="flex gap-2 max-h-[500px] overflow-y-hidden">
              <CreateTokenForm />
              <TokenAccountsList />
              {/* <MintTokenForm /> */}
            </div>
          </div>
        </div>
      </CoreProvider>
    );
  }
};
