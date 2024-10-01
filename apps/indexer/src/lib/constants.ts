import { PublicKey } from "@solana/web3.js";

import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";

export const DEFAULT_TIMESPAN = 30; // 30 seconds
export const DEFAULT_INCREASE_PCT = 5;
export const DEFAULT_MIN_TRADES = 10;

export const RAYDIUM_PUBLIC_KEY = RaydiumAmmParser.PROGRAM_ID;
export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

export const LOG_FILTERS = ["swap", RAYDIUM_PUBLIC_KEY.toString()];
