import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { AccountInfo, Connection, ParsedAccountData } from "@solana/web3.js";

import { PRICE_PRECISION, PROGRAMS, WRAPPED_SOL_MINT } from "@/lib/constants";
import { ParsedTokenBalanceInfo, Platform, PriceData, SwapAccounts } from "@/lib/types";

/* --------------------------------- DECODER -------------------------------- */
export const decodeSwapAccounts = (
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
  timestamp: number,
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
        return { vaultA: vaultA.pubkey, vaultB: vaultB.pubkey, platform: program.id, timestamp };
      }

      const swapAccountLabels =
        program.swaps.find((swap) => swap.name.toLowerCase() === ix.name.toLowerCase())?.accounts ?? [];
      if (swapAccountLabels.length === 0) return [];

      // For each label pair (it might be a two hop swap, so two pairs of accounts), find the corresponding token accounts
      return swapAccountLabels.map(([vaultALabel, vaultBLabel]) => {
        const vaultA = ix.accounts.find((account) => account.name === vaultALabel)?.pubkey;
        const vaultB = ix.accounts.find((account) => account.name === vaultBLabel)?.pubkey;
        if (!vaultA || !vaultB) return [];
        return { vaultA, vaultB, platform: program.id, timestamp };
      });
    })
    .flat() as SwapAccounts[];
};

/* ---------------------------------- PRICE --------------------------------- */
export const getPoolTokenPriceMultiple = async (
  connection: Connection,
  swapAccounts: SwapAccounts[],
): Promise<PriceData[]> => {
  if (swapAccounts.length === 0) return [];
  // Limit is 100 accounts per request
  if (swapAccounts.length >= 100) throw new Error("Attempting to pass too many accounts to getMultipleParsedAccounts");

  const res = await connection.getMultipleParsedAccounts(
    swapAccounts.map(({ vaultA, vaultB }) => [vaultA, vaultB]).flat(),
    {
      commitment: "confirmed",
    },
  );

  // For each pair of vaults, parse the data and calculate the price of the token swapped against WSOL
  return res.value.reduce((acc, _, index, array) => {
    if (index % 2 === 0) {
      const formattedData = formatTokenBalanceResponse(array[index], array[index + 1], swapAccounts[index / 2]);
      if (!formattedData) return acc;
      const { wrappedSolVaultBalance, tokenVaultBalance, platform, timestamp } = formattedData;

      const tokenPrice =
        // If there is no token in the pool, we can consider the price to be 0
        tokenVaultBalance.tokenAmount.amount === "0"
          ? 0
          : Number(
              (BigInt(wrappedSolVaultBalance.tokenAmount.amount) *
                BigInt(PRICE_PRECISION) *
                BigInt(10 ** tokenVaultBalance.tokenAmount.decimals)) /
                (BigInt(tokenVaultBalance.tokenAmount.amount) *
                  BigInt(10 ** wrappedSolVaultBalance.tokenAmount.decimals)),
            );

      acc.push({
        mint: tokenVaultBalance.mint,
        price: tokenPrice,
        decimals: tokenVaultBalance.tokenAmount.decimals,
        platform,
        timestamp,
      });
    }
    return acc;
  }, [] as PriceData[]);
};

const formatTokenBalanceResponse = (
  resA: AccountInfo<Buffer | ParsedAccountData> | null | undefined,
  resB: AccountInfo<Buffer | ParsedAccountData> | null | undefined,
  swapAccounts: SwapAccounts | undefined,
):
  | {
      wrappedSolVaultBalance: ParsedTokenBalanceInfo;
      tokenVaultBalance: ParsedTokenBalanceInfo;
      platform: Platform;
      timestamp: number;
    }
  | undefined => {
  // Retrieve parsed info
  const vaultABalance = (resA?.data as ParsedAccountData | undefined)?.parsed.info as
    | ParsedTokenBalanceInfo
    | undefined;
  const vaultBBalance = (resB?.data as ParsedAccountData | undefined)?.parsed.info as
    | ParsedTokenBalanceInfo
    | undefined;
  if (!vaultABalance || !vaultBBalance) return;

  // Separate Wrapped SOL (if it's present) and token swapped against WSOL
  const wrappedSolBalance =
    vaultABalance.mint === WRAPPED_SOL_MINT.toString()
      ? vaultABalance
      : vaultBBalance.mint === WRAPPED_SOL_MINT.toString()
        ? vaultBBalance
        : undefined;
  if (!wrappedSolBalance) return;
  const tokenBalance = wrappedSolBalance === vaultABalance ? vaultBBalance : vaultABalance;

  return {
    wrappedSolVaultBalance: wrappedSolBalance,
    tokenVaultBalance: tokenBalance,
    platform: swapAccounts?.platform ?? "n/a",
    timestamp: swapAccounts?.timestamp ?? Date.now(),
  };
};
