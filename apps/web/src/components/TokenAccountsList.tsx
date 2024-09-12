import { useEffect, useState } from "react";
import { useTokenStore } from "../store/tokenStore";
import { useCore } from "../hooks/useCore";
import { fetchDigitalAsset } from "@metaplex-foundation/mpl-token-metadata";
import { BN } from "@coral-xyz/anchor";
import { Keypair, PublicKey } from "@solana/web3.js";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";

interface TokenInfo {
  account: Keypair;
  address: string;
  name: string;
  symbol: string;
  mintAmount: string;
  supply: bigint;
  uri: string;
}

export default function TokenAccountsList() {
  const { umi, programs } = useCore();
  const { publicKey, sendTransaction } = useWallet();
  const { connection } = useConnection();
  const tokenAccounts = useTokenStore((state) => state.tokenAccounts);
  const [tokenInfos, setTokenInfos] = useState<TokenInfo[]>([]);
  const [isLoading, setIsLoading] = useState<{ [key: number]: boolean }>({});

  const fetchTokenInfos = async () => {
    const infos = await Promise.all(
      tokenAccounts.map((account) => {
        try{
          return fetchDigitalAsset(umi, account.publicKey as any);
        } catch (error) {
          console.error("Error fetching token info:", error);
          return null;
        }
      })
    );

    setTokenInfos(
      infos.reduce((acc: TokenInfo[], info, i) => {
        if (info) {
          acc.push({
            account: tokenAccounts[i],
            address: info.mint.publicKey.toString(),
            name: info.metadata.name,
            symbol: info.metadata.symbol,
            uri: info.metadata.uri,
            supply: info.mint.supply,
            mintAmount: "0",
          });
        }
        return acc;
      }, [] as TokenInfo[])
    );
  };

  useEffect(() => {
    const fetchInterval = setInterval(() => {
      console.log("Fetching token infos...");

      fetchTokenInfos();
    }, 5000); // 10000 milliseconds = 10 seconds

    // Initial fetch
    fetchTokenInfos();

    // Cleanup function to clear the interval when the component unmounts
    return () => clearInterval(fetchInterval);
  }, []);

  const handleMint = async (e: React.FormEvent, index: number) => {
    e.preventDefault();
    if (!publicKey) return;

    setIsLoading((prev) => ({ ...prev, [index]: true }));

    const info = tokenInfos[index];

    try {
      // Amount of tokens to mint.
      const amount = new BN(info.mintAmount);

      const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
        new PublicKey(info.address),
        publicKey
      );

      console.log("Creating transaction...");
      const transaction = await programs.createToken.methods
        .mintToken(amount)
        .accountsPartial({
          mintAuthority: publicKey,
          recipient: publicKey,
          mintAccount: new PublicKey(info.address),
          associatedTokenAccount: associatedTokenAccountAddress,
        })
        .transaction();

      transaction.feePayer = publicKey;
      transaction.recentBlockhash = (
        await connection.getLatestBlockhash()
      ).blockhash;

      console.log("Sending transaction...");

      const transactionSignature = await sendTransaction(
        transaction,
        connection
      );

      console.log("Transaction sent successfully");
      console.log(
        `View on explorer: https://solana.fm/tx/${transactionSignature}?cluster=devnet-alpha`
      );
    } catch (error) {
      console.error("Error minting token:", error);
    } finally {
      setIsLoading((prev) => ({ ...prev, [index]: false }));
    }
  };

  if (!publicKey) return <div>Connect your wallet</div>;
  return (
    <div className="relative w-[400px] p-2 bg-slate-300 rounded-xl shadow-lg">
      <button
        className="absolute top-4 right-4 hover:bg-blue-600 bg-blue-500 text-white p-2 rounded-md text-sm transition-colors duration-200"
        onClick={fetchTokenInfos}
      >
        Refresh
      </button>
      <h2 className="font-bold text-center text-gray-800 mb-6">
        Created Tokens
      </h2>
      <p className = "uppercase text-xs text-center font-bold text-orange-500">IT TAKES ~15 SECONDS TO UPDATE</p>
      {tokenInfos.length === 0 ? (
        <p className="text-center text-gray-500">No tokens created yet.</p>
      ) : (
        <ul className="flex flex-col gap-2 max-h-[400px] overflow-y-scroll scrollbar-thin scrollbar-thumb-rounded-full scrollbar-thumb-gray-400 pr-2">
          {tokenInfos.map((info, i) => (
            <li
              key={info.address}
              className="bg-slate-100/50 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow duration-200"
            >
              <p className="text-sm font-semibold text-gray-600">Address:</p>
              <p className="text-xs text-gray-800 break-all mb-1">
                {info.address}
              </p>
              <div className="grid grid-cols-2">
                <div>
                  <p className="text-sm font-semibold text-gray-600">Name:</p>
                  <p className="text-sm text-gray-800">{info.name}</p>
                </div>

                <div className="">
                  <p className="text-sm font-semibold text-gray-600">Symbol:</p>
                  <p className="text-sm text-gray-800">{info.symbol}</p>
                </div>
                <div className="">
                  <p className="text-sm font-semibold text-gray-600">Uri:</p>
                  <a
                    href={info.uri}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-xs text-blue-500 break-all hover:underline"
                  >
                    {info.uri.slice(8, 24)}...
                  </a>
                </div>

                <div className="">
                  <p className="text-sm font-semibold text-gray-600">Supply:</p>
                  <p className="text-xs text-blue-500 break-all hover:underline">
                    {info.supply.toString()}
                  </p>
                </div>
              </div>

              <form
                onSubmit={(e) => handleMint(e, i)}
                className="flex flex-row gap-2 bg-slate-500/50 rounded-md p-2"
              >
                <input
                  type="number"
                  value={info.mintAmount}
                  onChange={(e) =>
                    setTokenInfos((prev) =>
                      prev.map((info, index) =>
                        index === i
                          ? { ...info, mintAmount: e.target.value ?? "0" }
                          : info
                      )
                    )
                  }
                  className="p-2 rounded-md text-sm"
                  min="1"
                />
                <button
                  type="submit"
                  disabled={!publicKey || isLoading[i]}
                  className="btn-primary text-sm"
                >
                  {isLoading[i] ? "Minting..." : "Mint Tokens"}
                </button>
              </form>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
