#!/usr/bin/env tsx

import { Keypair } from "@solana/web3.js";
import bs58 from "bs58";

// Generate a new keypair
const keypair = Keypair.generate();

// Convert the private key to base58
const base58Key = bs58.encode(keypair.secretKey);

console.log("\n=== New Solana Keypair ===\n");
console.log("Public Key:", keypair.publicKey.toBase58());
console.log("\nPrivate Key (base58):");
console.log(base58Key);
console.log("\n=== Add to .env file ===\n");
console.log(`PRIVATE_KEY="${base58Key}"\n`);
