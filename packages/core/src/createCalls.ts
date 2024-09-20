import { Wallet } from "@coral-xyz/anchor";
import { Connection } from "@solana/web3.js";

import { Programs } from "./types";

export const createCalls = (wallet: Wallet, connection: Connection, programs: Programs) => {
  const increment = async () : Promise<string> => {
    try{
    const transaction = await programs.counter.methods.increment().transaction();

    // for some reason this returns early
    const {blockhash, lastValidBlockHeight} = await connection.getLatestBlockhash()
    transaction.recentBlockhash = blockhash;
    transaction.lastValidBlockHeight = lastValidBlockHeight;
    await wallet.signTransaction(transaction);

    const txId = await connection.sendRawTransaction(transaction.serialize());

    await connection.confirmTransaction({
      blockhash: transaction.recentBlockhash,
      lastValidBlockHeight: lastValidBlockHeight,
      signature: txId,
    });
      console.log(`View on explorer: https://solana.fm/tx/${txId}?cluster=devnet-alpha`);
      return 'yes'
    } catch (error) {
      console.log(error);
      return 'no'
    }
  };

  return {
    increment,
  };
};
