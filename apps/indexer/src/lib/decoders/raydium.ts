import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { VersionedTransactionResponse } from "@solana/web3.js";

import { SwapAccounts } from "@/lib/types";

export const decodeRaydiumTx = (
  tx: VersionedTransactionResponse,
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  if (parsedIxs.length === 0) return [];
  // Format the transaction
  // const logsEvents = logsParser.parse(parsedIxs, tx.meta?.logMessages ?? []);
  // const result = { instructions: parsedIxs, events: logsEvents };

  // Retrieve the swap instruction and get the token accounts
  const swapIx = parsedIxs.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return [];

  const poolCoin = swapIx.accounts.find((account) => account.name === "poolCoinTokenAccount")?.pubkey;
  const poolPc = swapIx.accounts.find((account) => account.name === "poolPcTokenAccount")?.pubkey;

  if (!poolCoin || !poolPc) return [];
  return [{ tokenX: poolCoin, tokenY: poolPc, platform: "raydium" }];
};
