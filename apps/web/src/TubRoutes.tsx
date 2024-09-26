import { useWallet } from "@solana/wallet-adapter-react";
import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Balance } from "./components/Balance";
import { NavBar } from "./components/NavBar";
import ServerStatus from "./components/ServerStatus";
import { Coins } from "./screens/Coins";
import IncrementForm from "./screens/IncrementForm";
import { TubProvider } from "./providers/TubProvider";
import { useTub } from "./hooks/useTub";
import { RegisterPane } from "./components/RegisterPane";

export const TubRoutes = () => {
  const { publicKey, wallet } = useWallet();
  const { userId } = useTub();

  if (!wallet || !publicKey) {
    return (
      <div>
        Please connect a wallet.
        <WalletMultiButton />
      </div>
    );
  }

  if (!userId) {
    return <RegisterPane />;
  }
  return (
    <TubProvider>
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

        <BrowserRouter>
          <NavBar />
          <div className="relative max-w-[400px] h-4/5 bg-black rounded-xl p-4 pt-10 overflow-hidden">
            <Routes>
              <Route path="/" element={<Coins publicKey={publicKey} />} />
              <Route path="/counter" element={<IncrementForm />} />
              <Route
                path="*"
                element={
                  <div className="text-white text-2xl">
                    404 - Page Not Found
                  </div>
                }
              />
            </Routes>
          </div>
        </BrowserRouter>
      </div>
    </TubProvider>
  );
};
