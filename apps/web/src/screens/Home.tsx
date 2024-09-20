import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { useWallet } from "@solana/wallet-adapter-react";
import { CoreProvider } from "../providers/CoreProvider";
import IncrementForm from "../components/IncrementForm";
import { Balance } from "../components/Balance";
import ServerStatus from "../components/ServerStatus";

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
              <div className="flex gap-2 bg-slate-300 rounded-md p-2 text-sm">
                Balance: <Balance publicKey={publicKey} />
              </div>
            </div>
            <div></div>
            <div className="flex flex-col gap-2">
              <ServerStatus />
              <IncrementForm />
            </div>
          </div>
        </div>
      </CoreProvider>
    );
  }
};
