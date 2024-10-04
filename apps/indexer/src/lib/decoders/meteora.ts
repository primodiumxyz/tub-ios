import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { PublicKey, VersionedTransactionResponse } from "@solana/web3.js";

import { SwapAccounts } from "@/lib/types";

export const decodeMeteoraTx = (
  tx: VersionedTransactionResponse,
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts | undefined => {
  if (parsedIxs.length === 0) return;
  // Retrieve the swap instruction and get the token accounts
  const swapIx = parsedIxs.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return;

  // These are strings as bnLayoutFormatter formatted them to base58
  const tokenXMint = swapIx.accounts.find((account) => account.name === "tokenXMint")?.pubkey;
  const tokenYMint = swapIx.accounts.find((account) => account.name === "tokenYMint")?.pubkey;

  if (!tokenXMint || !tokenYMint) return;
  return { tokenX: new PublicKey(tokenXMint), tokenY: new PublicKey(tokenYMint), platform: "meteora" };
};
