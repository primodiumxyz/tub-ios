// Copied and fixed from https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249
import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";

import { parseLogs } from "@/lib/parsers/logs-parser/helpers";
import { LogEvent, RaydiumAmmLogsParser } from "@/lib/parsers/logs-parser/raydium-amm-logs-parser";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";

const RAYDIUM_AMM_PROGRAM_ID = RaydiumAmmParser.PROGRAM_ID.toBase58();

export class LogsParser {
  raydiumAmmLogsParser = new RaydiumAmmLogsParser();
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parse(actions: ParsedInstruction<Idl, string>[], logMessages: string[]): LogEvent[] {
    if (!this.isValidIx(actions)) {
      return [];
    }

    const logs = parseLogs(logMessages);
    return actions
      .map((action, index) => {
        if ("info" in action) {
          return;
        } else {
          const programId = action.programId.toBase58();
          switch (programId) {
            case RAYDIUM_AMM_PROGRAM_ID: {
              return logs[index] ? this.raydiumAmmLogsParser.parse(action, logs[index]) : undefined;
            }
            default:
              return;
          }
        }
      })
      .filter((log) => Boolean(log)) as LogEvent[];
  }

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  isValidIx(actions: ParsedInstruction<Idl, string>[]): boolean {
    return actions.some((action) => action.programId.toBase58() === RAYDIUM_AMM_PROGRAM_ID);
  }
}
