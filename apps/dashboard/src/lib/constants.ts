import { Codex } from "@codex-data/sdk";

export const CODEX_SDK = new Codex(import.meta.env.VITE_CODEX_API_KEY);
export const NETWORK_FILTER = [1399811149]; // Solana
