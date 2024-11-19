#!/usr/bin/env tsx

import { Keypair } from "@solana/web3.js";

// Generate a new keypair
const keypair = Keypair.generate();

// Get the raw private key bytes and convert to base64
const base64Key = Buffer.from(keypair.secretKey).toString('base64');

console.log('\n=== New Solana Keypair ===\n');
console.log('Public Key:', keypair.publicKey.toBase58());
console.log('\nPrivate Key (base64):');
console.log(base64Key);
console.log('\n=== Add to .env file ===\n');
console.log(`PRIVATE_KEY="${base64Key}"\n`); 