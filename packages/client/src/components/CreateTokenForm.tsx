import { useState } from "react";

import "../index.css";
import { useCore } from "../hooks/useCore";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { PublicKey, SystemProgram } from "@solana/web3.js";

export default function CreateTokenForm() {
  const { programs, constants, pdas, keypairs } = useCore();
  const { connection } = useConnection();
  const { publicKey, sendTransaction } = useWallet();
  const [isLoading, setIsLoading] = useState(false);
  const [tokenName, setTokenName] = useState("Tub Test");
  const [tokenSymbol, setTokenSymbol] = useState("TUB");
  const [tokenUri, setTokenUri] = useState(
    "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json"
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!publicKey) {
      console.error("No public key found");
      return;
    }

    setIsLoading(true);

    try {
      if (publicKey != null) {
        console.log("Creating transaction...");
        const transaction = await programs.createToken.methods
          .createToken(tokenName, tokenSymbol, tokenUri)
          .accountsPartial({
            mintAccount: new PublicKey(constants.ADDRESS_TOKEN_MINT_ACCOUNT),
            metadataAccount: pdas.createToken,
            payer: publicKey.toString(),
            tokenProgram: new PublicKey(constants.ADDRESS_TOKEN_PROGRAM),
            tokenMetadataProgram: new PublicKey(
              constants.ADDRESS_TOKEN_METADATA_PROGRAM
            ),
            systemProgram: SystemProgram.programId,
            rent: new PublicKey("SysvarRent111111111111111111111111111111111"),
          })
          .signers([keypairs.tokenMintAccount])
          .transaction();

        transaction.feePayer = publicKey;
        transaction.recentBlockhash = (
          await connection.getLatestBlockhash()
        ).blockhash;
        transaction.sign(keypairs.tokenMintAccount);
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
      <h2 className="form-title">Create Token</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="tokenName" className="form-label">
            Token Name
          </label>
          <input
            type="text"
            id="tokenName"
            value={tokenName}
            onChange={(e) => setTokenName(e.target.value)}
            className="form-input"
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="tokenSymbol" className="form-label">
            Token Symbol
          </label>
          <input
            type="text"
            id="tokenSymbol"
            value={tokenSymbol}
            onChange={(e) => setTokenSymbol(e.target.value)}
            className="form-input"
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="tokenUri" className="form-label">
            Token URI
          </label>
          <input
            type="url"
            id="tokenUri"
            value={tokenUri}
            onChange={(e) => setTokenUri(e.target.value)}
            className="form-input"
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
              Creating Token...
            </>
          ) : (
            "Create Token"
          )}
        </button>
      </form>
    </div>
  );
}
