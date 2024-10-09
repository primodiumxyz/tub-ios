import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import { PROGRAMS } from "@/lib/constants";
import { SolanaParser } from "@/lib/parsers/solana-parser";

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

export const ixParser = new SolanaParser([]);
PROGRAMS.forEach((program) => {
  const parser = new program.parser();
  ixParser.addParser(program.publicKey, parser.parseInstruction.bind(parser));
});
