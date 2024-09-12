import { createContext, ReactNode, useMemo } from "react";
import { createCore } from "../core/createCore";
import { useConnection, Wallet } from "@solana/wallet-adapter-react";
import { Core } from "../core/types";
import { PublicKey } from "@solana/web3.js";

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

  const core = useMemo(() => createCore(publicKey, wallet, connection), [publicKey, wallet, connection]);


  return <CoreContext.Provider value={core}>{children}</CoreContext.Provider>;
};