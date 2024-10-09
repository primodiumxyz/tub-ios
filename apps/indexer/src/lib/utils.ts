import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { Connection, GetVersionedBlockConfig } from "@solana/web3.js";

import { LOG_FILTERS, PROGRAMS, WRAPPED_SOL_MINT } from "@/lib/constants";
import { ParsedAccountData, PriceData, SwapAccounts } from "@/lib/types";

export const filterLogs = (logs: string[]) => {
  const filtered = logs?.filter((log) =>
    LOG_FILTERS.some((filter) => log.toLowerCase().includes(filter.toLowerCase())),
  );
  return filtered && filtered.length > 0 ? filtered : undefined;
};

export const getVersionedBlockConfig: GetVersionedBlockConfig = {
  commitment: "finalized",
  maxSupportedTransactionVersion: 0,
  rewards: false,
  transactionDetails: "full",
};

/* --------------------------------- DECODER -------------------------------- */
export const decodeSwapAccounts = (
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  // Filter out the instructions that are not related to the exchanges
  const programIxs = parsedIxs.filter((ix) =>
    PROGRAMS.some(
      (program) =>
        program.publicKey.toString() === ix.programId.toString() &&
        ("swaps" in program
          ? program.swaps.some((swap) => swap.name.toLowerCase() === ix.name.toLowerCase())
          : program.parser.getSwapInstructionNames().includes(ix.name.toLowerCase())),
    ),
  );
  if (programIxs.length === 0) return [];

  // For each instruction
  return programIxs
    .map((ix) => {
      // find the program object
      const program = PROGRAMS.find((program) => program.publicKey.toString() === ix.programId.toString())!;

      // find the label pairs of the swapped tokens accounts
      if (!("swaps" in program)) {
        // this is a minimal parser
        const [vaultA, vaultB] = ix.accounts;
        if (!vaultA || !vaultB) return [];
        return { vaultA: vaultA.pubkey, vaultB: vaultB.pubkey, platform: program.id };
      }

      const swapAccountLabels =
        program.swaps.find((swap) => swap.name.toLowerCase() === ix.name.toLowerCase())?.accounts ?? [];
      if (swapAccountLabels.length === 0) return [];

      // For each label pair (it might be a two hop swap, so two pairs of accounts), find the corresponding token accounts
      return swapAccountLabels.map(([vaultALabel, vaultBLabel]) => {
        const vaultA = ix.accounts.find((account) => account.name === vaultALabel)?.pubkey;
        const vaultB = ix.accounts.find((account) => account.name === vaultBLabel)?.pubkey;
        if (!vaultA || !vaultB) return [];
        return { vaultA, vaultB, platform: program.id };
      });
    })
    .flat() as SwapAccounts[];
};

/* ---------------------------------- PRICE --------------------------------- */
export const getPoolTokenPrice = async (
  connection: Connection,
  { vaultA, vaultB, platform }: SwapAccounts,
): Promise<PriceData | undefined> => {
  const [vaultARes, vaultBRes] = (
    await connection.getMultipleParsedAccounts([vaultA, vaultB], {
      commitment: "confirmed",
    })
  ).value;

  const vaultAData = vaultARes?.data as ParsedAccountData | undefined;
  const vaultBData = vaultBRes?.data as ParsedAccountData | undefined;

  const vaultAParsedInfo = vaultAData?.parsed.info;
  const vaultBParsedInfo = vaultBData?.parsed.info;

  if (
    !(vaultAParsedInfo?.mint === WRAPPED_SOL_MINT.toString()) ||
    !vaultBParsedInfo?.mint ||
    !vaultAParsedInfo?.tokenAmount?.uiAmount ||
    !vaultBParsedInfo?.tokenAmount?.uiAmount
  )
    return;

  const tokenPrice = vaultAParsedInfo.tokenAmount.uiAmount / vaultBParsedInfo.tokenAmount.uiAmount;
  return { mint: vaultBParsedInfo.mint, price: tokenPrice, platform };
};
