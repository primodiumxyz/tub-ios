import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import {
  MeteoraDlmmParser,
  OrcaWhirlpoolParser,
  RaydiumAmmParser,
  RaydiumClmmParser,
  SolanaParser,
} from "@/lib/parsers";

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

export const meteoraDlmmParser = new MeteoraDlmmParser();
export const orcaWhirlpoolParser = new OrcaWhirlpoolParser();
export const raydiumAmmParser = new RaydiumAmmParser();
export const raydiumClmmParser = new RaydiumClmmParser();
export const ixParser = new SolanaParser([]);
ixParser.addParser(MeteoraDlmmParser.PROGRAM_ID, meteoraDlmmParser.parseInstruction.bind(meteoraDlmmParser));
ixParser.addParser(OrcaWhirlpoolParser.PROGRAM_ID, orcaWhirlpoolParser.parseInstruction.bind(orcaWhirlpoolParser));
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumAmmParser.parseInstruction.bind(raydiumAmmParser));
ixParser.addParser(RaydiumClmmParser.PROGRAM_ID, raydiumClmmParser.parseInstruction.bind(raydiumClmmParser));
