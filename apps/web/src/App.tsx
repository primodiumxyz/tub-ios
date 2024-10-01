import { WalletAdapterNetwork } from "@solana/wallet-adapter-base";
import { ConnectionProvider, WalletProvider } from "@solana/wallet-adapter-react";
import { WalletModalProvider } from "@solana/wallet-adapter-react-ui";
import { PhantomWalletAdapter } from "@solana/wallet-adapter-wallets";
import { clusterApiUrl } from "@solana/web3.js";
import { useMemo } from "react";
import { Provider as UrqlProvider } from "urql";
// Import wallet adapter CSS
import "@solana/wallet-adapter-react-ui/styles.css";
import { createClient as createGqlClient } from "@tub/gql";
import { ServerProvider } from "./providers/ServerProvider";
import { TubProvider } from "./providers/TubProvider";
import { TubRoutes } from "./TubRoutes";

const gqlClientUrl = import.meta.env.VITE_GRAPHQL_URL! as string;

export default function App() {
  const network = WalletAdapterNetwork.Devnet;
  const endpoint = useMemo(() => clusterApiUrl(network), [network]);
  const wallets = useMemo(() => [new PhantomWalletAdapter()], []);
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

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
