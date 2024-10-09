import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { GetVersionedBlockConfig } from "@solana/web3.js";

import { LOG_FILTERS, PROGRAMS, WRAPPED_SOL_MINT } from "@/lib/constants";
import { connection } from "@/lib/setup";
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
      (program) => program.publicKey.toString() === ix.programId.toString(),
      // program.swaps.some((swap) => swap.name.toLowerCase() === ix.name.toLowerCase()),
    ),
  );
  if (programIxs.length === 0) return [];
  // console.log(programIxs.map((ix) => ix.name));

  // For each instruction
  return programIxs
    .map((ix) => {
      // find the program object
      const program = PROGRAMS.find((program) => program.publicKey.toString() === ix.programId.toString());
      // find the label pairs of the swapped tokens accounts
      const swapAccountLabels =
        program?.swaps.find((swap) => swap.name.toLowerCase() === ix.name.toLowerCase())?.accounts ?? [];
      if (!program || swapAccountLabels.length === 0) return [];

      // For each label pair (it might be a two hop swap, so two pairs of accounts), find the corresponding token accounts
      return swapAccountLabels.map(([tokenXLabel, tokenYLabel]) => {
        const tokenX = ix.accounts.find((account) => account.name === tokenXLabel)?.pubkey;
        const tokenY = ix.accounts.find((account) => account.name === tokenYLabel)?.pubkey;
        if (!tokenX || !tokenY) return [];
        return { tokenX, tokenY, platform: program.id };
      });
    })
    .flat() as SwapAccounts[];
};

/* ---------------------------------- PRICE --------------------------------- */
export const getPoolTokenPrice = async ({ tokenX, tokenY, platform }: SwapAccounts): Promise<PriceData | undefined> => {
  const [tokenXRes, tokenYRes] = (
    await connection.getMultipleParsedAccounts([tokenX, tokenY], {
      commitment: "confirmed",
    })
  ).value;

  const tokenXData = tokenXRes?.data as ParsedAccountData | undefined;
  const tokenYData = tokenYRes?.data as ParsedAccountData | undefined;

  const tokenXParsedInfo = tokenXData?.parsed.info;
  const tokenYParsedInfo = tokenYData?.parsed.info;

  if (
    !(tokenXParsedInfo?.mint === WRAPPED_SOL_MINT.toString()) ||
    !tokenYParsedInfo?.mint ||
    !tokenXParsedInfo?.tokenAmount?.uiAmount ||
    !tokenYParsedInfo?.tokenAmount?.uiAmount
  )
    return;

  const tokenPrice = tokenXParsedInfo.tokenAmount.uiAmount / tokenYParsedInfo.tokenAmount.uiAmount;
  return { mint: tokenYParsedInfo.mint, price: tokenPrice, platform };
};
