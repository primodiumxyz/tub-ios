import * as anchor from "@coral-xyz/anchor";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";
import { Keypair, PublicKey } from "@solana/web3.js";
import type { Tub } from "../target/types/tub";
import { BN } from "@coral-xyz/anchor";
import { expect } from "chai";

describe("Tub Token Creator", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const payer = provider.wallet as anchor.Wallet;
  const program = anchor.workspace.Tub as anchor.Program<Tub>;

  const metadata = {
    name: "Solana Gold",
    symbol: "GOLDSOL",
    uri: "https://raw.githubusercontent.com/solana-developers/program-examples/new-examples/tokens/tokens/.assets/spl-token.json",
  };

  // Generate new keypair to use as address for mint account.

  it("Create a Tub Token!", async () => {

  const mintKeypair = new Keypair();
    const prevBalance = await provider.connection.getBalance(payer.publicKey);
    console.log({ prevBalance });

    const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
      mintKeypair.publicKey,
      payer.publicKey
    );
    const transactionSignature = await program.methods
      .createToken(metadata.name, metadata.symbol, metadata.uri)
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

  it("Create an SPL Token!", async () => {
  const mintKeypair = new Keypair();
    const transactionSignature = await program.methods
      .createToken(metadata.name, metadata.symbol, metadata.uri)
      .accounts({
        payer: payer.publicKey,
        mintAccount: mintKeypair.publicKey,
      })
      .signers([mintKeypair])
      .rpc();

    console.log("Success!");
    console.log(`   Mint Address: ${mintKeypair.publicKey}`);
    console.log(`   Transaction Signature: ${transactionSignature}`);
  });

  it("Mint some tokens to your wallet!", async () => {
  const mintKeypair = new Keypair();
    // Derive the associated token address account for the mint and payer.
    const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
      mintKeypair.publicKey,
      payer.publicKey
    );

    // Amount of tokens to mint.
    const amount = new anchor.BN(100);

    // Mint the tokens to the associated token account.
    const transactionSignature = await program.methods
      .mintToken(amount)
      .accountsPartial({
        mintAuthority: payer.publicKey,
        recipient: payer.publicKey,
        mintAccount: mintKeypair.publicKey,
        associatedTokenAccount: associatedTokenAccountAddress,
      })
      .rpc();

    console.log("Success!");
    console.log(
      `Associated Token Account Address: ${associatedTokenAccountAddress}`
    );
    console.log(`Transaction Signature: ${transactionSignature}`);
  });
});