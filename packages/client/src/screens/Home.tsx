import { WalletMultiButton } from "@solana/wallet-adapter-react-ui";
import { useWallet } from "@solana/wallet-adapter-react";

export const Home = () => {
  const { publicKey } = useWallet();

  if (!publicKey) {
    return (
      <div>
        Please connect a wallet.
        <WalletMultiButton />
      </div>
    );
  } else {
    return (
      <div>
        <p>Connected wallet: {publicKey.toString()}</p>
        <WalletMultiButton />
      </div>
    );
  }
};
