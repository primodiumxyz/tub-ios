import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm";
import { OrcaWhirlpoolParser } from "./parsers/orca-whirlpool";
import { RaydiumAmmParser } from "./parsers/raydium-amm";

export const PRICE_DATA_BATCH_SIZE = 300;
export const PRICE_PRECISION = 10 ** 18;

export const PLATFORMS = ["meteora-dlmm", "orca-whirlpool", "raydium-lp-v4"] as const;
export const METEORA_DLMM_PUBLIC_KEY = MeteoraDlmmParser.PROGRAM_ID;
export const ORCA_WHIRLPOOL_PUBLIC_KEY = OrcaWhirlpoolParser.PROGRAM_ID;
export const RAYDIUM_AMM_PUBLIC_KEY = RaydiumAmmParser.PROGRAM_ID;
export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

export const LOG_FILTERS = [
  METEORA_DLMM_PUBLIC_KEY.toString(),
  ORCA_WHIRLPOOL_PUBLIC_KEY.toString(),
  RAYDIUM_AMM_PUBLIC_KEY.toString(),
];
