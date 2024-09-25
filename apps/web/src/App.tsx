import { WalletAdapterNetwork } from "@solana/wallet-adapter-base";
import {
  ConnectionProvider,
  WalletProvider,
} from "@solana/wallet-adapter-react";
import { WalletModalProvider } from "@solana/wallet-adapter-react-ui";
import { PhantomWalletAdapter } from "@solana/wallet-adapter-wallets";
import { clusterApiUrl } from "@solana/web3.js";
import { useMemo } from "react";
import { Provider as UrqlProvider } from "urql";

// Import wallet adapter CSS
import "@solana/wallet-adapter-react-ui/styles.css";
import { ServerProvider } from "./contexts/serverContext";
import { TubRoutes } from "./AppLoadingState";
import { createClient as createGqlClient } from "@tub/gql";

export default function App() {
  const network = WalletAdapterNetwork.Devnet;
  const endpoint = useMemo(() => clusterApiUrl(network), [network]);
  const wallets = useMemo(() => [new PhantomWalletAdapter()], []);
  const gqlClient = useMemo(() => createGqlClient({ url: import.meta.env.VITE_GRAPHQL_URL }), []);

  return (
    // Solana Providers and Adapters
    <UrqlProvider value={gqlClient}>
      <ServerProvider>
        <ConnectionProvider endpoint={endpoint}>
          <WalletProvider wallets={wallets} autoConnect>
            <WalletModalProvider>
              <TubRoutes />
            </WalletModalProvider>
          </WalletProvider>
        </ConnectionProvider>
      </ServerProvider>
    </UrqlProvider>
  );
}
