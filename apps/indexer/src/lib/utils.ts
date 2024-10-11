import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { Connection } from "@solana/web3.js";

import { PROGRAMS, WRAPPED_SOL_MINT } from "@/lib/constants";
import { ParsedAccountData, PriceData, SwapAccounts } from "@/lib/types";

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
const fetches = {};
let timeElapsed = 0;
setInterval(() => {
  console.log("Time elapsed", `${timeElapsed}s`);
  console.log(
    "Total swaps",
    Object.values(fetches).reduce((a: number, b: number) => a + b, 0),
  );
  console.log(
    "Per platform",
    Object.entries(fetches).sort((a, b) => b[1] - a[1]),
  );
  timeElapsed++;
}, 1000);
export const getPoolTokenPrice = async (
  connection: Connection,
  { vaultA, vaultB, platform }: SwapAccounts,
): Promise<PriceData | undefined> => {
  fetches[platform] = (fetches[platform] ?? 0) + 1;
  return;
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
