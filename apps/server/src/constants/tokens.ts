import { PublicKey } from "@solana/web3.js";

/** USDC token mint address for devnet */
export const USDC_DEV_PUBLIC_KEY = new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU");

/** USDC token mint address for mainnet */
export const USDC_MAINNET_PUBLIC_KEY = new PublicKey("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");

/** Native SOL mint address */
export const SOL_MAINNET_PUBLIC_KEY = new PublicKey("So11111111111111111111111111111111111111112");

/** Associated Token Account (ATA) program ID */
export const ATA_PROGRAM_PUBLIC_KEY = new PublicKey("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");

/** SPL Token program ID */
export const TOKEN_PROGRAM_PUBLIC_KEY = new PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");

/** Jupiter DEX aggregator program ID */
export const JUPITER_PROGRAM_PUBLIC_KEY = new PublicKey("JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4");

/** Maximum compute units allowed per transaction on Solana */
export const MAX_CHAIN_COMPUTE_UNITS = 1_400_000;

/** Size in bytes of a token account on Solana */
export const TOKEN_ACCOUNT_SIZE = 165;

/** Number of lamports in 1 SOL */
export const LAMPORTS_PER_SOL = 1_000_000_000;

/** Number of base units in 1 USDC (6 decimals) */
export const USDC_BASE_UNITS = 1_000_000;

// ------------ TEST CONSTANTS ------------

/** MEME token mint address to buy */
export const MEMECOIN_MAINNET_PUBLIC_KEY = new PublicKey("98mb39tPFKQJ4Bif8iVg9mYb9wsfPZgpgN1sxoVTpump");
