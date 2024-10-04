import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm-parser";
import { RaydiumAmmParser } from "./parsers/raydium-amm-parser";

export const PRICE_DATA_BATCH_SIZE = 100;
export const PRICE_PRECISION = 10 ** 18;

export const PLATFORMS = ["raydium", "meteora"] as const;
export const RAYDIUM_PUBLIC_KEY = RaydiumAmmParser.PROGRAM_ID;
export const METEORA_PUBLIC_KEY = MeteoraDlmmParser.PROGRAM_ID;

export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

export const LOG_FILTERS = [RAYDIUM_PUBLIC_KEY.toString(), METEORA_PUBLIC_KEY.toString()];
