import { useCallback, useEffect, useState } from "react";
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

export default function TokenAccountsList({
  account,
  publicKey,
}: {
  account: Keypair;
  publicKey: PublicKey;
}) {
  const { umi, programs } = useCore();
  const { sendTransaction } = useWallet();
  const { connection } = useConnection();

  const [tokenInfo, setTokenInfo] = useState<TokenInfo | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const fetchTokenInfo = useCallback(async () => {
    try {
      const digitalAsset =
        (await fetchDigitalAsset(umi, account.publicKey as any)) ?? null;
      const info = digitalAsset
        ? {
            account,
          address: digitalAsset.mint.publicKey.toString(),
          name: digitalAsset.metadata.name,
          symbol: digitalAsset.metadata.symbol,
          mintAmount: tokenInfo?.mintAmount ?? "1",
          supply: digitalAsset.mint.supply,
          uri: digitalAsset.metadata.uri,
        }
      : null;

      if (info) setTokenInfo(info);
    } catch (error) {
      console.error("Error fetching token info:", error);
    }
  }, [umi, account, tokenInfo]);

  useEffect(() => {
    const fetchInterval = setInterval(() => {
      console.log("Fetching token infos...");

      fetchTokenInfo();
    }, 5000); // 10000 milliseconds = 10 seconds

    // Cleanup function to clear the interval when the component unmounts
    return () => clearInterval(fetchInterval);
  }, [fetchTokenInfo]);

  const handleMint = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!publicKey || !tokenInfo) return;

    setIsLoading(true);

    try {
      // Amount of tokens to mint.
      const amount = new BN(tokenInfo.mintAmount);

      const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
        new PublicKey(tokenInfo.address),
        publicKey
      );

      console.log("Creating transaction...");
      const transaction = await programs.createToken.methods
        .mintToken(amount)
        .accountsPartial({
          mintAuthority: publicKey,
          recipient: publicKey,
          mintAccount: new PublicKey(tokenInfo.address),
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
      setIsLoading(false);
    }
  };

  if (!tokenInfo) return null;
  return (
    <div className="relative bg-slate-100/50 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow duration-200">
      <button
        className="absolute top-1 right-1 hover:bg-blue-600 bg-blue-500 text-white p-1 rounded-md text-xs transition-colors duration-200"
        onClick={fetchTokenInfo}
      >
        Refresh
      </button>
      <p className="text-sm font-semibold text-gray-600">Address:</p>
      <p className="text-xs text-gray-800 break-all mb-1">
        {tokenInfo.address}
      </p>
      <div className="grid grid-cols-2">
        <div>
          <p className="text-sm font-semibold text-gray-600">Name:</p>
          <p className="text-sm text-gray-800">{tokenInfo.name}</p>
        </div>

        <div className="">
          <p className="text-sm font-semibold text-gray-600">Symbol:</p>
          <p className="text-sm text-gray-800">{tokenInfo.symbol}</p>
        </div>
        <div className="">
          <p className="text-sm font-semibold text-gray-600">Uri:</p>
          <a
            href={tokenInfo.uri}
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs text-blue-500 break-all hover:underline"
          >
            {tokenInfo.uri.slice(8, 24)}...
          </a>
        </div>

        <div className="">
          <p className="text-sm font-semibold text-gray-600">Supply:</p>
          <p className="text-xs">{tokenInfo.supply.toString()}</p>
        </div>
      </div>

      <form
        onSubmit={(e) => handleMint(e)}
        className="flex flex-row gap-2 bg-slate-500/50 rounded-md p-2"
      >
        <input
          type="number"
          value={tokenInfo.mintAmount}
          onChange={(e) =>
            setTokenInfo((prev) =>
              prev ? { ...prev, mintAmount: e.target.value ?? "0" } : null
            )
          }
          className="p-2 rounded-md text-sm"
          min="1"
        />
        <button
          type="submit"
          disabled={!publicKey || isLoading}
          className="btn-primary text-sm"
        >
          {isLoading ? "Minting..." : "Mint Tokens"}
        </button>
      </form>
    </div>
  );
}
