import * as anchor from "@coral-xyz/anchor";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";
import { Keypair, PublicKey } from "@solana/web3.js";
import type { TubToken } from "../target/types/tub_token";
import { BN } from "@coral-xyz/anchor";
import { expect } from "chai";

describe("Tub Token Creator", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const payer = provider.wallet as anchor.Wallet;
  const program = anchor.workspace.TubToken as anchor.Program<TubToken>;

  const metadata = {
    name: "Solana Gold",
    symbol: "GOLDSOL",
    uri: "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json",
  };

  // Generate new keypair to use as address for mint account.
  const mintKeypair = new Keypair();

  it("Create a Tub Token!", async () => {

    const prevBalance = await provider.connection.getBalance(payer.publicKey);
    console.log({ prevBalance });

    const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
      mintKeypair.publicKey,
      payer.publicKey
    );
    const transactionSignature = await program.methods
      .createTubToken(metadata.name, metadata.symbol, metadata.uri, new BN(1e9))
      .accounts({
        payer: payer.publicKey,
        mintAccount: mintKeypair.publicKey,
      })
      .signers([mintKeypair])
      .rpc();

    console.log("Success!");
    console.log(`   Mint Address: ${mintKeypair.publicKey}`);
    console.log(`   Transaction Signature: ${transactionSignature}`);

    // // it should mint 1e9 tokens * 100_000 to the mint address
    // const mintBalance = await provider.connection.getTokenAccountBalance(new PublicKey(mintKeypair.publicKey));
    // expect(Number(mintBalance.value.amount)).to.be.eq(prevMintBalance.value.amount + 1e9 * 100_000);
    // // it should transfer 1e9 tokens from the payer address to the mint address
    // const newBalance = await provider.connection.getBalance(payer.publicKey);
    // expect(newBalance).to.be.eq(prevBalance - 1e9);
  });
});
