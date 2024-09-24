import { useWallet } from "@solana/wallet-adapter-react";
import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Balance } from "./components/Balance";
import { NavBar } from "./components/NavBar";
import ServerStatus from "./components/ServerStatus";
import { CoreProvider } from "./providers/CoreProvider";
import { Coins } from "./screens/Coins";
import IncrementForm from "./screens/IncrementForm";

export const TubRoutes = () => {
  const { publicKey, wallet } = useWallet();

  if (!wallet || !publicKey) {
    return (
      <div>
        Please connect a wallet.
        <WalletMultiButton />
      </div>
    );
  }

  return (
    <CoreProvider wallet={wallet} publicKey={publicKey}>
      <BrowserRouter>
        <div className="flex flex-col items-center justify-center w-screen h-screen">
          <div className="absolute top-2 right-2">
            <WalletMultiButton />
            {publicKey && (
              <div className="flex gap-2 bg-slate-300 rounded-md p-2 text-sm">
                Balance: <Balance publicKey={publicKey} />
              </div>
            )}
          </div>

          <ServerStatus />
          <div className="relative w-4/5 h-4/5 bg-slate-200 rounded-xl p-10 pt-4">
            <NavBar />
            <Routes>
              <Route path="/" element={<IncrementForm />} />
              <Route path="/coins" element={<Coins />} />
            </Routes>
          </div>
        </div>
      </BrowserRouter>
    </CoreProvider>
  );
};
