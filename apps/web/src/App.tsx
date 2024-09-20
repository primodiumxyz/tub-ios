import { WalletAdapterNetwork } from "@solana/wallet-adapter-base";
import {
  ConnectionProvider,
  WalletProvider,
} from "@solana/wallet-adapter-react";
import { WalletModalProvider } from "@solana/wallet-adapter-react-ui";
import { PhantomWalletAdapter } from "@solana/wallet-adapter-wallets";
import { clusterApiUrl } from "@solana/web3.js";
import { useMemo } from "react";

import AppLoadingState from "./AppLoadingState";

// Import wallet adapter CSS
import "@solana/wallet-adapter-react-ui/styles.css";
import { ServerProvider } from "./contexts/serverContext";

export default function App() {
  const network = WalletAdapterNetwork.Devnet;
  const endpoint = useMemo(() => clusterApiUrl(network), [network]);
  const wallets = useMemo(() => [new PhantomWalletAdapter()], []);

  return (
    // Solana Providers and Adapters
    <ServerProvider>
      <ConnectionProvider endpoint={endpoint}>
        <WalletProvider wallets={wallets} autoConnect>
          <WalletModalProvider>
            {/* Screens */}
            <AppLoadingState />
          </WalletModalProvider>
        </WalletProvider>
      </ConnectionProvider>
    </ServerProvider>
  );
}
