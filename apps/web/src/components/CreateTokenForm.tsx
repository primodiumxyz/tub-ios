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
      const transaction = await programs.createToken.methods
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
    <div className="create-token-form">
      <h2 className="form-title">Create Token</h2>
      <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
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
        <div
          style={{
            padding: "1rem",
            display: "flex",
            flexDirection: "column",
            background: "rgba(128, 0, 128, 0.1)",
          }}
        >
          <p>
            Token Account: {tokenMintAccount?.publicKey.toString() ?? "None"}
          </p>
<button
          type="button"
          onClick={generateTokenAccount}
          className="submit-button"
        >
          Generate Token
        </button>

        </div>
        
          <button
            type="submit"
           disabled={isLoading || publicKey == null || tokenMintAccount == null}
            className="submit-button"
          >
            {isLoading ? (
              <>
                <span className="loading-spinner"></span>
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
