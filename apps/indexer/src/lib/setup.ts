import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import { PROGRAMS } from "@/lib/constants";
import { SolanaParser } from "@/lib/parsers/solana-parser";
import { TransactionFormatter } from "@/lib/transaction-formatter";

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

export const connection = new Connection(`https://mainnet.helius-rpc.com/?api-key=${env.HELIUS_API_KEY}`, {
  commitment: "confirmed",
  // @ts-expect-error Property 'referrer' is missing in type 'import("undici-types/fetch").Request'
  fetch: fetchWithRetry,
});

export const txFormatter = new TransactionFormatter();
export const ixParser = new SolanaParser();
PROGRAMS.forEach((program) =>
  ixParser.addParser(program.publicKey, program.parser.parseInstruction.bind(program.parser)),
);
