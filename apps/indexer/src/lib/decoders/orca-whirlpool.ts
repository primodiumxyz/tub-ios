import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { VersionedTransactionResponse } from "@solana/web3.js";

import { SwapAccounts } from "@/lib/types";

export const decodeOrcaWhirlpoolTx = (
  tx: VersionedTransactionResponse,
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  if (parsedIxs.length === 0) return [];
  // Retrieve the swap instruction and get the token accounts
  const swapIx = parsedIxs.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return [];

  // TODO: twoHopSwapV2 ?

  // "twoHopSwap"
  if (swapIx.name === "twoHopSwap") {
    const tokenXMintA = swapIx.accounts.find((account) => account.name === "tokenVaultOneA")?.pubkey;
    const tokenYMintA = swapIx.accounts.find((account) => account.name === "tokenVaultOneB")?.pubkey;
    const tokenXMintB = swapIx.accounts.find((account) => account.name === "tokenVaultTwoA")?.pubkey;
    const tokenYMintB = swapIx.accounts.find((account) => account.name === "tokenVaultTwoB")?.pubkey;

    if (!tokenXMintA || !tokenYMintA || !tokenXMintB || !tokenYMintB) return [];
    return [
      { tokenX: tokenXMintA, tokenY: tokenYMintA, platform: "orca" },
      { tokenX: tokenXMintB, tokenY: tokenYMintB, platform: "orca" },
    ];
  }

  // "swap" and "twoHopSwap"
  const tokenXMint = swapIx.accounts.find((account) => account.name === "tokenVaultA")?.pubkey;
  const tokenYMint = swapIx.accounts.find((account) => account.name === "tokenVaultB")?.pubkey;

  if (!tokenXMint || !tokenYMint) return [];
  return [{ tokenX: tokenXMint, tokenY: tokenYMint, platform: "orca" }];
};
