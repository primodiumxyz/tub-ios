import { createContext, ReactNode, useMemo } from "react";
import { useConnection, Wallet } from "@solana/wallet-adapter-react";
import { PublicKey } from "@solana/web3.js";
import { Core, createCore } from "@tub/core";
import { SignerWalletAdapter } from "@solana/wallet-adapter-base";
import { Wallet as AnchorWallet } from "@coral-xyz/anchor";

export const CoreContext = createContext<Core | null>(null);

type Props = {
  children: ReactNode;
  wallet: Wallet;
  publicKey: PublicKey;
};

/**
 * Provides the core context to its children components.
 *
 * @component
 * @param {Props} props - The component props.
 * @param {React.ReactNode} props.children - The children components.
 * @param {object} props.value - The value to be provided by the context.
 * @returns {JSX.Element} The rendered component.
 */
export const CoreProvider = ({ children, wallet, publicKey }: Props): JSX.Element => {
  const { connection } = useConnection();

  
  const walletAdapter = useMemo(() => ({
    ...(wallet.adapter as SignerWalletAdapter),
    publicKey,
  }) as unknown as AnchorWallet, [wallet, publicKey]);

  const core = useMemo(() => createCore(walletAdapter, connection), [walletAdapter, connection]);


  return <CoreContext.Provider value={core}>{children}</CoreContext.Provider>;
};