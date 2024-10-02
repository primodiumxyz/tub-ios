import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { PublicKey, VersionedTransactionResponse } from "@solana/web3.js";

import { RAYDIUM_PUBLIC_KEY } from "@/lib/constants";
import { logsParser } from "@/lib/setup";
import { SwapAccounts } from "@/lib/types";

export const decodeRaydiumTx = (
  tx: VersionedTransactionResponse,
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts | undefined => {
  const programIxs = parsedIxs.filter((ix) => ix.programId.equals(RAYDIUM_PUBLIC_KEY));

  // Format the transaction
  if (programIxs.length === 0) return;
  const logsEvents = logsParser.parse(parsedIxs, tx.meta?.logMessages ?? []);
  const result = { instructions: parsedIxs, events: logsEvents };

  // Retrieve the swap instruction and get the token accounts
  const swapIx = result.instructions.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return;

  // These are strings as bnLayoutFormatter formatted them to base58
  const poolCoin = swapIx.accounts.find((account) => account.name === "poolCoinTokenAccount")?.pubkey;
  const poolPc = swapIx.accounts.find((account) => account.name === "poolPcTokenAccount")?.pubkey;

  if (!poolCoin || !poolPc) return;
  return { poolCoin: new PublicKey(poolCoin), poolPc: new PublicKey(poolPc), result };
};
