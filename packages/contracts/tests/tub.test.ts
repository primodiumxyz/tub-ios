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

  describe("Initialize a token", () => {
    it("token gets created", async () => {
      const mintKeypair = new Keypair();
      const prevBalance = await provider.connection.getBalance(payer.publicKey);
      console.log({ prevBalance });

      const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
        mintKeypair.publicKey,
        payer.publicKey
      );

      const _cost = 1e9;
      const cost = new BN(_cost);
      const transactionSignature = await program.methods
        .initToken(metadata.name, metadata.symbol, metadata.uri, cost)
        .accountsPartial({
          payer: payer.publicKey,
          mintAccount: mintKeypair.publicKey,
          associatedTokenAccount: associatedTokenAccountAddress,
          associatedTokenProgram: anchor.utils.token.ASSOCIATED_PROGRAM_ID
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

      const newPayerBalance = await provider.connection.getBalance(
        payer.publicKey
      );
      expect(newPayerBalance).to.be.lte(
        prevBalance - _cost,
        "new payer balance incorrect"
      );

      const newMintBalance = await provider.connection.getBalance(
        mintKeypair.publicKey
      );
      expect(newMintBalance).to.be.gte(_cost, "new mint balance incorrect");

      const mintBalance = await provider.connection.getTokenAccountBalance(
        associatedTokenAccountAddress
      );
      expect(Number(mintBalance.value.amount) ).to.be.eq(_cost * 100_000);
    });

  });

  describe("Create and mint a token", () => {
    const mintKeypair = new Keypair();
    it("Create an SPL Token!", async () => {
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
      // Derive the associated token address account for the mint and payer.
      const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
        mintKeypair.publicKey,
        payer.publicKey
      );

      // Amount of tokens to mint.
      const _amount = 100;
      const amount = new anchor.BN(_amount);

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
      const mintBalance = await provider.connection.getTokenAccountBalance(
        associatedTokenAccountAddress
      );
      expect(Number(mintBalance.value.amount) / 1e9).to.be.eq(_amount);
    });
  });
});
