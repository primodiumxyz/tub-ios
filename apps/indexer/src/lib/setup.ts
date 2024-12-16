import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";
import { SolanaParser } from "@/lib/parsers/solana-parser";
import { TransactionFormatter } from "@/lib/transaction-formatter";
import { fetchWithRetry } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

export const connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`, {
  commitment: "confirmed",
  // @ts-expect-error Property 'referrer' is missing in type 'import("undici-types/fetch").Request'
  fetch: fetchWithRetry,
});

export const txFormatter = new TransactionFormatter();
export const ixParser = new SolanaParser();
export const raydiumAmmParser = new RaydiumAmmParser();
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumAmmParser.parseInstruction.bind(raydiumAmmParser));
