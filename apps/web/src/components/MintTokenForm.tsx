import { useState } from "react";

import "../index.css";
import { useCore } from "../hooks/useCore";
import { BN } from "@coral-xyz/anchor";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { PublicKey } from "@solana/web3.js";

export default function MintTokenForm() {
  const { programs, constants } = useCore();
  const { connection } = useConnection();
  const { publicKey, sendTransaction } = useWallet();
  const [isLoading, setIsLoading] = useState(false);
  const [tokenPublicKey, setTokenPublicKey] = useState(
    constants.ADDRESS_TOKEN_MINT_ACCOUNT
  );
  const [tokenMintAmount, setTokenMintAmount] = useState(100);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!publicKey) {
      console.error("No public key found");
      return;
    }

    setIsLoading(true);

    try {
      if (publicKey != null) {
        // Amount of tokens to mint.
        const amount = new BN(tokenMintAmount);

        const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
          new PublicKey(tokenPublicKey),
          publicKey
        );

        console.log("Creating transaction...");
        const transaction = await programs.createToken.methods
          .mintToken(amount)
          .accountsPartial({
            mintAuthority: publicKey,
            recipient: publicKey,
            mintAccount: new PublicKey(tokenPublicKey),
            associatedTokenAccount: associatedTokenAccountAddress,
          })
          .transaction();

        transaction.feePayer = publicKey;
        transaction.recentBlockhash = (
          await connection.getLatestBlockhash()
        ).blockhash;
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
      }
    } catch (error) {
      console.error("Error creating token:", error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="create-token-form">
      <h2 className="form-title">Mint Tokens</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="tokenPublicKey" className="form-label">
            Token Public Key
          </label>
          <input
            type="text"
            id="tokenPublicKey"
            value={tokenPublicKey}
            onChange={(e) => setTokenPublicKey(e.target.value)}
            className="form-input"
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="tokenSymbol" className="form-label">
            Token Mint Amount
          </label>
          <input
            type="text"
            id="tokenSymbol"
            value={tokenMintAmount}
            onChange={(e) => setTokenMintAmount(parseInt(e.target.value))}
            className="form-input"
            required
          />
        </div>
        <button
          type="submit"
          disabled={!publicKey || isLoading}
          className="submit-button"
        >
          {isLoading ? (
            <>
              <span className="loading-spinner"></span>
              Minting Token...
            </>
          ) : (
            "Mint Token"
          )}
        </button>
      </form>
    </div>
  );
}
