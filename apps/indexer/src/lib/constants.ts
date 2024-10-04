import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm-parser";
import { OrcaWhirlpoolParser } from "./parsers/orca-whirlpool-amm-parser";
import { RaydiumAmmParser } from "./parsers/raydium-amm-parser";

export const PRICE_DATA_BATCH_SIZE = 100;
export const PRICE_PRECISION = 10 ** 18;

export const PLATFORMS = ["meteora", "orca", "raydium"] as const;
export const METEORA_PUBLIC_KEY = MeteoraDlmmParser.PROGRAM_ID;
export const ORCA_PUBLIC_KEY = OrcaWhirlpoolParser.PROGRAM_ID;
export const RAYDIUM_PUBLIC_KEY = RaydiumAmmParser.PROGRAM_ID;
export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

export const LOG_FILTERS = [METEORA_PUBLIC_KEY.toString(), ORCA_PUBLIC_KEY.toString(), RAYDIUM_PUBLIC_KEY.toString()];
