import { useState } from "react";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { PublicKey, SystemProgram } from "@solana/web3.js";
import {
  programs,
  ADDRESS_TOKEN_MINT_ACCOUNT,
  createTokenPDA,
  ADDRESS_TOKEN_PROGRAM,
  ADDRESS_TOKEN_METADATA_PROGRAM,
} from "../anchor/setup";

export default function CreateTokenForm() {
  const { publicKey, sendTransaction } = useWallet();
  const { connection } = useConnection();
  const [isLoading, setIsLoading] = useState(false);

  const onClick = async () => {
    if (!publicKey) return;

    setIsLoading(true);

    try {
      console.log(createTokenPDA);

      const transaction = await programs.createToken.methods
        .createToken(
          "Tub Test", // tokenName
          "TUB", // tokenSymbol
          "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json" // tokenUri
        )
        .accountsPartial({
          mintAccount: new PublicKey(ADDRESS_TOKEN_MINT_ACCOUNT),
          metadataAccount: createTokenPDA,
          payer: publicKey,
          tokenProgram: new PublicKey(ADDRESS_TOKEN_PROGRAM),
          tokenMetadataProgram: new PublicKey(ADDRESS_TOKEN_METADATA_PROGRAM),
          systemProgram: SystemProgram.programId,
          rent: new PublicKey("SysvarRent111111111111111111111111111111111"),
        })
        .transaction();

      const transactionSignature = await sendTransaction(
        transaction,
        connection
      );

      console.log(
        `View on explorer: https://solana.fm/tx/${transactionSignature}?cluster=devnet-alpha`
      );
    } catch (error) {
      console.log(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button className="w-24" onClick={onClick} disabled={!publicKey}>
      {isLoading ? "Loading" : "Mint Token"}
    </button>
  );
}
