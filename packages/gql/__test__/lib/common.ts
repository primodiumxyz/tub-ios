import { Keypair } from "@solana/web3.js";

export function createWallet() {
  const wallet = Keypair.generate();
  return wallet.publicKey.toString();
}