import { Codex } from "@codex-data/sdk";

export const CODEX_SDK = new Codex(import.meta.env.VITE_CODEX_API_KEY);
export const NETWORK_FILTER = [1399811149]; // Solana
export const PUMP_FUN_ADDRESS = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";
export const RESOLUTION = "60"; // time frame for trending results in minutes,
export const INTERVALS = [60, 240, 720, 1440]; // in minutes
