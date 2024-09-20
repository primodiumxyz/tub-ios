import { Wallet } from "@coral-xyz/anchor";
import { Connection } from "@solana/web3.js";
import { Programs } from "./types";

export const createCalls = (wallet: Wallet, connection: Connection, programs: Programs) => {
  const increment = async () => {
    try {
      const transaction = await programs.counter.methods.increment().transaction();

      const signedTx = await wallet.signTransaction(transaction);
      const txId = await connection.sendRawTransaction(signedTx.serialize());
      const latestBlockHash = await connection.getLatestBlockhash();

      await connection.confirmTransaction({
        blockhash: latestBlockHash.blockhash,
        lastValidBlockHeight: latestBlockHash.lastValidBlockHeight,
        signature: txId,
      });
      console.log(`View on explorer: https://solana.fm/tx/${txId}?cluster=devnet-alpha`);
    } catch (error) {
      console.log(error);
    }
  };

  return {
    increment,
  };
};
