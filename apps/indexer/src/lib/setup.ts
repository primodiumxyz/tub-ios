import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import { TransactionFormatter } from "@/lib/formatters/transaction-formatter";
import { MeteoraDlmmParser, RaydiumAmmParser, SolanaParser } from "@/lib/parsers";
import { LogsParser } from "@/lib/parsers/logs-parser";

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

// @ts-expect-error Property 'referrer' is missing in type 'import("undici-types/fetch").Request'
export const connection = new Connection(env.ALCHEMY_RPC_URL, { commitment: "confirmed", fetch: fetchWithRetry });

export const txFormatter = new TransactionFormatter();
export const raydiumParser = new RaydiumAmmParser();
export const meteoraDlmmParser = new MeteoraDlmmParser();
export const ixParser = new SolanaParser([]);
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumParser.parseInstruction.bind(raydiumParser));
ixParser.addParser(MeteoraDlmmParser.PROGRAM_ID, meteoraDlmmParser.parseInstruction.bind(meteoraDlmmParser));
export const logsParser = new LogsParser();
