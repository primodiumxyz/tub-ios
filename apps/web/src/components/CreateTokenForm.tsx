import { useCallback, useState } from "react";

import "../index.css";
import { useCore } from "../hooks/useCore";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { Keypair, PublicKey, SystemProgram } from "@solana/web3.js";
import { useTokenStore } from "../store/tokenStore";

export default function CreateTokenForm() {
  const { programs, constants } = useCore();
  const { connection } = useConnection();
  const { publicKey, sendTransaction } = useWallet();
  const [isLoading, setIsLoading] = useState(false);
  const [tokenName, setTokenName] = useState("Tub Test");
  const [tokenSymbol, setTokenSymbol] = useState("TUB");
  const [tokenUri, setTokenUri] = useState(
    "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json"
  );
  const [tokenMintAccount, setTokenMintAccount] = useState<Keypair | null>(
    null
  );
  const { addTokenAccount } = useTokenStore();

  const generateTokenAccount = useCallback(() => {
    const newTokenMintAccount = new Keypair();
    setTokenMintAccount(newTokenMintAccount);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!publicKey) {
      console.error("No public key found");
      return;
    }

    setIsLoading(true);
    if (publicKey == null || tokenMintAccount == null) {
      return;
    }
    console.log("Creating transaction...");

    // PDA of CreateToken, the program that creates new tokens
    // seeds = [b"metadata", token_metadata_program.key().as_ref(), mint_account.key().as_ref()],

    const tokenMetadataProgramKey = new PublicKey(
      constants.ADDRESS_TOKEN_METADATA_PROGRAM
    );
    const [createTokenPDA] = PublicKey.findProgramAddressSync(
      [
        Buffer.from("metadata"),
        tokenMetadataProgramKey.toBuffer(),
        tokenMintAccount.publicKey.toBuffer(),
      ],
      tokenMetadataProgramKey
    );

    try {
      const transaction = await programs.tub.methods
        .createToken(tokenName, tokenSymbol, tokenUri)
        .accountsPartial({
          mintAccount: tokenMintAccount.publicKey,
          metadataAccount: createTokenPDA,
          payer: publicKey.toString(),
          tokenProgram: new PublicKey(constants.ADDRESS_TOKEN_PROGRAM),
          tokenMetadataProgram: new PublicKey(
            constants.ADDRESS_TOKEN_METADATA_PROGRAM
          ),
          systemProgram: SystemProgram.programId,
          rent: new PublicKey("SysvarRent111111111111111111111111111111111"),
        })
        .signers([tokenMintAccount])
        .transaction();

      transaction.feePayer = publicKey;
      transaction.recentBlockhash = (
        await connection.getLatestBlockhash()
      ).blockhash;
      transaction.sign(tokenMintAccount);
      console.log(
        transaction
          .serialize({ verifySignatures: false, requireAllSignatures: false })
          .toString("base64")
      );

      console.log(JSON.stringify(transaction));

      console.log(transaction.serializeMessage().toString("base64"));
      console.log("Transaction created successfully", { transaction });
      console.log("Sending transaction...");

      const transactionSignature = await sendTransaction(
        transaction,
        connection,
        {
          // skipPreflight: true,
          // preflightCommitment: "confirmed",
        }
      );

      console.log("Transaction sent successfully");
      console.log(
        `View on explorer: https://solana.fm/tx/${transactionSignature}?cluster=devnet-alpha`
      );
      addTokenAccount(tokenMintAccount);
    } catch (error) {
      console.error("Error creating token:", error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-[400px] p-2 bg-slate-300 rounded-xl shadow-md flex flex-col gap-2">
      <h2 className="text-base font-bold text-center  text-gray-800">
        Create Token
      </h2>
      <form onSubmit={handleSubmit} className="w-full flex flex-col gap-2">
        <div>
          <label
            htmlFor="tokenName"
            className="block text-sm font-medium text-gray-600"
          >
            Token Name
          </label>
          <input
            type="text"
            id="tokenName"
            value={tokenName}
            onChange={(e) => setTokenName(e.target.value)}
            className="w-full p-2 border border-gray-300 rounded-md text-base transition-colors focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
            required
          />
        </div>
        <div className="">
          <label
            htmlFor="tokenSymbol"
            className="block text-sm font-medium text-gray-600"
          >
            Token Symbol
          </label>
          <input
            type="text"
            id="tokenSymbol"
            value={tokenSymbol}
            onChange={(e) => setTokenSymbol(e.target.value)}
            className="w-full p-2 border border-gray-300 rounded-md text-base transition-colors focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
            required
          />
        </div>
        <div className="">
          <label
            htmlFor="tokenUri"
            className="block text-sm font-medium text-gray-600"
          >
            Token URI
          </label>
          <input
            type="url"
            id="tokenUri"
            value={tokenUri}
            onChange={(e) => setTokenUri(e.target.value)}
            className="w-full p-2 border border-gray-300 rounded-md text-base transition-colors focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
          />
        </div>
        <div className="p-4 flex flex-col bg-slate-600 bg-opacity-10 rounded-md">
          <p className="text-wrap text-sm text-gray-600 overflow-x-auto pb-2">
            Token Account: {tokenMintAccount?.publicKey.toString() ?? "None"}
          </p>
          <button
            type="button"
            onClick={generateTokenAccount}
            className="w-full py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white border-none rounded-md text-base font-medium cursor-pointer transition-all hover:translate-y-[-1px] disabled:opacity-60 disabled:cursor-not-allowed mt-2"
          >
            Generate Token
          </button>
        </div>

        <button
          type="submit"
          disabled={isLoading || publicKey == null || tokenMintAccount == null}
          className="w-full py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white border-none rounded-md text-base font-medium cursor-pointer transition-all hover:translate-y-[-1px] disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {isLoading ? (
            <>
              <span className="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></span>
              Creating Token...
            </>
          ) : (
            "Submit Transaction"
          )}
        </button>
      </form>
    </div>
  );
}
