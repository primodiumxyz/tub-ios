import { parseEnv } from "@bin/parseEnv";
import { SolanaParser } from "@shyft-to/solana-transaction-parser";
import { Connection } from "@solana/web3.js";

import { TransactionFormatter } from "@/lib/formatters/transaction-formatter";
import { LogsParser } from "@/lib/parsers/logs-parser";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";

const env = parseEnv();

export const connection = new Connection(env.ALCHEMY_RPC_URL, "confirmed");

export const txFormatter = new TransactionFormatter();
export const raydiumParser = new RaydiumAmmParser();
export const ixParser = new SolanaParser([]);
ixParser.addParser(RaydiumAmmParser.PROGRAM_ID, raydiumParser.parseInstruction.bind(raydiumParser));
export const logsParser = new LogsParser();
