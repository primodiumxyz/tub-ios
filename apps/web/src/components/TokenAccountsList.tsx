import { useEffect, useState } from "react";
import { useTokenStore } from "../store/tokenStore";
import { useCore } from "../hooks/useCore";
import { fetchDigitalAsset, } from "@metaplex-foundation/mpl-token-metadata";

interface TokenInfo {
  address: string;
  name: string;
  symbol: string;
  uri: string;
}

export default function TokenAccountsList() {
  const { umi } = useCore();
  const tokenAccounts = useTokenStore((state) => state.tokenAccounts);
  const [tokenInfos, setTokenInfos] = useState<TokenInfo[]>([]);

  const fetchTokenInfos = async () => {
    const infos = await Promise.all(tokenAccounts.map((account) => {
      return fetchDigitalAsset(umi, account.publicKey as any);
    }));


    setTokenInfos(infos.map((info) => ({
      address: info.mint.publicKey.toString(),
      name: info.metadata.name,
      symbol: info.metadata.symbol,
      uri: info.metadata.uri,
    })));
  };

  useEffect(() => {
    fetchTokenInfos();
  }, []);

  return (
    <div className="relative w-[400px] p-4 bg-white rounded-xl shadow-lg">
      <button className="absolute top-4 right-4 hover:bg-blue-600 bg-blue-500 text-white px-3 py-1 rounded-md text-sm transition-colors duration-200" onClick={fetchTokenInfos}>
        Refresh
      </button>
      <h2 className="text-xl font-bold text-center text-gray-800 mb-4">
        Created Tokens
      </h2>
      {tokenInfos.length === 0 ? (
        <p className="text-center text-gray-500">No tokens created yet.</p>
      ) : (
        <ul className="flex flex-col gap-4 max-h-[400px] overflow-y-auto pr-2">
          {tokenInfos.map((info) => (
            <li key={info.address} className="bg-gray-50 rounded-lg p-3 shadow-sm hover:shadow-md transition-shadow duration-200">
              <p className="text-sm font-semibold text-gray-600 mb-1">Address:</p>
              <p className="text-xs text-gray-800 break-all mb-2">{info.address}</p>
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-sm font-semibold text-gray-600">Name:</p>
                  <p className="text-sm text-gray-800">{info.name}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-gray-600">Symbol:</p>
                  <p className="text-sm text-gray-800">{info.symbol}</p>
                </div>
              </div>
              <p className="text-sm font-semibold text-gray-600 mt-2">URI:</p>
              <p className="text-xs text-blue-500 break-all hover:underline">
                <a href={info.uri} target="_blank" rel="noopener noreferrer">{info.uri}</a>
              </p>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
