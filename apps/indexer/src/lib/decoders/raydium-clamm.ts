import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";

import { SwapAccounts } from "@/lib/types";

export const decodeRaydiumCLAMMTx = (
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  if (parsedIxs.length === 0) return [];

  // Retrieve the swap instruction and get the token accounts
  const swapIx = parsedIxs.find((ix) => ix.name.toLowerCase().includes("swap"));
  if (!swapIx) return [];

  const inputVault = swapIx.accounts.find((account) => account.name === "inputVault")?.pubkey;
  const outputVault = swapIx.accounts.find((account) => account.name === "outputVault")?.pubkey;

  if (!inputVault || !outputVault) return [];
  return [{ tokenX: inputVault, tokenY: outputVault, platform: "raydium-clamm" }];
};
