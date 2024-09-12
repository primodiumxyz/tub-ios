import { useEffect, useState } from "react";
import { useTokenStore } from "../store/tokenStore";
import { useConnection } from "@solana/wallet-adapter-react";
import { useCore } from "../hooks/useCore";

interface TokenInfo {
  address: string;
  name: string;
  symbol: string;
  uri: string;
}

export default function TokenAccountsList() {
  const { connection } = useConnection();
  const { constants, programs } = useCore();
  const tokenAccounts = useTokenStore((state) => state.tokenAccounts);
  const [tokenInfos, setTokenInfos] = useState<TokenInfo[]>([]);

  
  return (
    <div className="token-accounts-list">
      <h2>Created Tokens</h2>
{tokenAccounts.length === 0 ? (
        <p>No tokens created yet.</p>
      ) : (
        <ul>
          {tokenAccounts.map((account) => (
            <li key={account.publicKey.toString()}>
              <p>Address: {account.publicKey.toString()}</p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}