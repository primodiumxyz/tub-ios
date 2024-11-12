import { Connection } from "@solana/web3.js";
import { config } from "dotenv";
import { Helius } from "helius-sdk";

import { parseEnv } from "@bin/parseEnv";
import { SolanaParser } from "@/lib/parsers/solana-parser";
import { TransactionFormatter } from "@/lib/transaction-formatter";

import { RaydiumAmmParser } from "./parsers/raydium-amm-parser";

config({ path: "../../.env" });

const env = parseEnv();

const fetchWithRetry = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
  const timeout = 300_000; // 5min
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(input, {
      ...init,
      signal: controller.signal,
    });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    console.error(`Fetch error: ${String(error)}. Retrying in 5 seconds...`);
    await new Promise((resolve) => setTimeout(resolve, 5000));
    return fetchWithRetry(input, init);
  }
};

export const helius = new Helius(env.HELIUS_API_KEY);
export const connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`, {
  commitment: "confirmed",
  // @ts-expect-error Property 'referrer' is missing in type 'import("undici-types/fetch").Request'
  fetch: fetchWithRetry,
});

export const txFormatter = new TransactionFormatter();
export const ixParser = new SolanaParser();
export const raydiumAmmParser = new RaydiumAmmParser();
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumAmmParser.parseInstruction.bind(raydiumAmmParser));
