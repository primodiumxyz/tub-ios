import { useTokenStore } from "../store/tokenStore";
import { useWallet } from "@solana/wallet-adapter-react";
import TokenAccount from "./TokenAccount";

export default function TokenAccountsList() {
  const { publicKey } = useWallet();
  const tokenAccounts = useTokenStore((state) => state.tokenAccounts);

  if (!publicKey) return <div>Connect your wallet</div>;
  return (
    <div className="relative w-[400px] p-2 bg-slate-300 rounded-xl shadow-lg">
      <h2 className="font-bold text-center text-gray-800 mb-6">
        Created Tokens
      </h2>

      <p className="uppercase text-xs text-center font-bold text-orange-500">
        IT TAKES ~15 SECONDS TO UPDATE
      </p>

      {tokenAccounts.length === 0 && (
        <p className="text-center text-gray-500">No tokens created yet.</p>
      )}

      {tokenAccounts.map((account) => (
        <TokenAccount
          account={account}
          publicKey={publicKey}
          key={account.publicKey.toBase58()}
        />
      ))}
    </div>
  );
}
