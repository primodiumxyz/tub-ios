import { Connection } from "@solana/web3.js";
import { config } from "dotenv";

import { parseEnv } from "@bin/parseEnv";
import { TransactionFormatter } from "@/lib/formatters/transaction-formatter";
import { LogsParser } from "@/lib/parsers/logs-parser";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";
import { SolanaParser } from "@/lib/parsers/solana-parser";

config({ path: "../../.env" });

const env = parseEnv();

export const connection = new Connection(env.ALCHEMY_RPC_URL, "confirmed");

export const txFormatter = new TransactionFormatter();
export const raydiumParser = new RaydiumAmmParser();
export const ixParser = new SolanaParser([]);
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumParser.parseInstruction.bind(raydiumParser));
export const logsParser = new LogsParser();
