import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";

import { SwapAccounts } from "@/lib/types";

export const decodeMeteoraTx = (
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  if (parsedIxs.length === 0) return [];
  // Retrieve the swap instruction and get the token accounts
  const swapIx = parsedIxs.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return [];

  const tokenXMint = swapIx.accounts.find((account) => account.name === "tokenXMint")?.pubkey;
  const tokenYMint = swapIx.accounts.find((account) => account.name === "tokenYMint")?.pubkey;

  if (!tokenXMint || !tokenYMint) return [];
  return [{ tokenX: tokenXMint, tokenY: tokenYMint, platform: "meteora" }];
};
