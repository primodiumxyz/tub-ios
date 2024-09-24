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

            <NavBar />
          <div className="relative max-w-[400px] h-4/5 bg-black rounded-xl p-4 pt-10 overflow-hidden">
            <Routes>
              <Route path="/" element={<Coins />} />
              <Route path="/counter" element={<IncrementForm />} />
              <Route path="*" element={<div className="text-white text-2xl">404 - Page Not Found</div>} />
            </Routes>
          </div>
        </div>
      </BrowserRouter>
    </CoreProvider>
  );
};
