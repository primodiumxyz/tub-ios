import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Tub } from "../target/types/tub";
import { Keypair } from "@solana/web3.js";

describe("tub", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.Tub as Program<Tub>;
  const counterAccount = new Keypair();

  it("Is initialized!", async () => {
    // Invoke the initialize instruction
    const transactionSignature = await program.methods
      .initialize()
      .accounts({
        counter: counterAccount.publicKey,
      })
      .signers([counterAccount]) // include counter keypair as additional signer
      .rpc({ skipPreflight: true });

    // Fetch the counter account data
    const accountData = await program.account.counter.fetch(
      counterAccount.publicKey
    );

    console.log(`Transaction Signature: ${transactionSignature}`);
    console.log(`Count: ${accountData.count}`);
  });

  it("Increment", async () => {
    const transactionSignature = await program.methods
      .increment()
      .accounts({
        counter: counterAccount.publicKey,
      })
      .rpc();

    const accountData = await program.account.counter.fetch(
      counterAccount.publicKey
    );

    console.log(`Transaction Signature: ${transactionSignature}`);
    console.log(`Count: ${accountData.count}`);
  });
});
