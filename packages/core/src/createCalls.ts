import { Wallet } from "@coral-xyz/anchor";
import { Connection } from "@solana/web3.js";

import { Programs } from "./types";

export const createCalls = (wallet: Wallet, connection: Connection, programs: Programs) => {
  const increment = async () : Promise<string> => {
    console.log("incrementing call");
    try{
    const transaction = await programs.counter.methods.increment().transaction();

    transaction.feePayer = wallet.publicKey;
    // for some reason this returns early
    transaction.recentBlockhash = (await connection.getLatestBlockhash()).blockhash;
    console.log(transaction.recentBlockhash);
    await wallet.signTransaction(transaction);
    console.log(transaction.serialize({ verifySignatures: false, requireAllSignatures: false }).toString("base64"));

    const txId = await connection.sendRawTransaction(transaction.serialize());

    await connection.confirmTransaction({
      blockhash: transaction.recentBlockhash,
      lastValidBlockHeight: transaction.lastValidBlockHeight,
      signature: txId,
    });
      console.log(`View on explorer: https://solana.fm/tx/${txId}?cluster=devnet-alpha`);
      return 'yes'
    } catch (error) {
      console.log(error);
      return 'no'
    }
    console.log("post increment");
  };

  return {
    increment,
  };
};
