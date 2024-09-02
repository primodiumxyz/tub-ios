import * as anchor from "@coral-xyz/anchor";
import { CreateToken } from "../target/types/create_token";
import { Keypair } from "@solana/web3.js";

describe("Create Tokens", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const payer = provider.wallet as anchor.Wallet;
  const program = anchor.workspace.CreateToken as anchor.Program<CreateToken>;

  const metadata = {
    name: "Solana Gold",
    symbol: "GOLDSOL",
    uri: "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json",
  };

  // Amount of lamports included in transaction
  const amountLamports = new anchor.BN(1000000000); // 1 token with 9 decimals

  it("Create an SPL Token!", async () => {
    // Generate new keypair to use as address for mint account.
    const mintKeypair = new Keypair();

    // SPL Token default = 9 decimals
    const transactionSignature = await program.methods
      .createTokenMintWithAmount(
        9,
        metadata.name,
        metadata.symbol,
        metadata.uri,
        amountLamports
      )
      .accounts({
        payer: payer.publicKey,
        mintAccount: mintKeypair.publicKey,
      })
      .signers([mintKeypair])
      .rpc();

    console.log("Success!");
    console.log(`Mint Address: ${mintKeypair.publicKey}`);
    console.log(`Transaction Signature: ${transactionSignature}`);
  });
});
