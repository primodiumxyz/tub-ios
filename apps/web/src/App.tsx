import { WalletAdapterNetwork } from "@solana/wallet-adapter-base";
import {
  ConnectionProvider,
  WalletProvider,
} from "@solana/wallet-adapter-react";
import { WalletModalProvider } from "@solana/wallet-adapter-react-ui";
import { PhantomWalletAdapter } from "@solana/wallet-adapter-wallets";
import { clusterApiUrl } from "@solana/web3.js";
import { useMemo } from "react";
import { cacheExchange, fetchExchange, Provider as UrqlProvider } from "urql";

// Import wallet adapter CSS
import "@solana/wallet-adapter-react-ui/styles.css";
import { TubRoutes } from "./TubRoutes";
import { TubProvider } from "./providers/TubProvider";
import { ServerProvider } from "./providers/ServerProvider";
import { createClient } from "urql";

const gqlClientUrl = import.meta.env.VITE_GRAPHQL_URL! as string;

export default function App() {
  const network = WalletAdapterNetwork.Devnet;
  const endpoint = useMemo(() => clusterApiUrl(network), [network]);
  const wallets = useMemo(() => [new PhantomWalletAdapter()], []);
  const client = useMemo(
    () =>
      createClient({
        url: gqlClientUrl,
        exchanges: [cacheExchange, fetchExchange],
      }),
    []
  );

  return (
    // Solana Providers and Adapters

    <UrqlProvider value={client}>
      <ServerProvider>
        <TubProvider>
          <ConnectionProvider endpoint={endpoint}>
            <WalletProvider wallets={wallets} autoConnect>
              <WalletModalProvider>
                <TubRoutes />
              </WalletModalProvider>
            </WalletProvider>
          </ConnectionProvider>
        </TubProvider>
      </ServerProvider>
    </UrqlProvider>
  );
}
