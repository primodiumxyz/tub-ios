import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { Connection, ParsedAccountData, PublicKey } from "@solana/web3.js";
import { Helius } from "helius-sdk";

import { PRICE_PRECISION, PUMP_FUN_AUTHORITY, WRAPPED_SOL_MINT } from "@/lib/constants";
import { RaydiumAmmParser, SwapBaseInArgs, SwapBaseOutArgs } from "@/lib/parsers/raydium-amm-parser";
import { ParsedTokenBalanceInfo, PriceData, Swap, SwapType, TokenMetadata } from "@/lib/types";

/* --------------------------------- DECODER -------------------------------- */
export const decodeSwapData = <T extends SwapType = SwapType>(
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
  timestamp: number,
): Swap<T>[] => {
  // Filter out the instructions that are not related to a Raydium swap
  const programIxs = parsedIxs.filter(
    (ix) =>
      ix.programId.toString() === RaydiumAmmParser.PROGRAM_ID.toString() &&
      (ix.name.toLowerCase() === "swapBaseIn" || ix.name.toLowerCase() === "swapBaseOut"),
  );
  if (programIxs.length === 0) return [];

  // For each instruction
  return programIxs
    .map((ix) => {
      const vaultA = ix.accounts.find((account) => account.name === "poolCoinTokenAccount")?.pubkey;
      const vaultB = ix.accounts.find((account) => account.name === "poolTokenTokenAccount")?.pubkey;
      if (!vaultA || !vaultB) return;

      return {
        vaultA,
        vaultB,
        type: (ix.name.toLowerCase() === "swapBaseIn" ? SwapType.IN : SwapType.OUT) as T,
        args: ix.args as T extends SwapType.IN ? SwapBaseInArgs : SwapBaseOutArgs,
        timestamp,
      };
    })
    .filter((swap) => swap !== undefined);
};

/* ------------------------------ PROCESS DATA ------------------------------ */
export const processVaultsData = async <T extends SwapType = SwapType>(
  connection: Connection,
  helius: Helius,
  vaultPairs: PublicKey[][],
  swaps: Swap<T>[],
): Promise<{
  tokensMetadata: TokenMetadata[];
  priceData: PriceData[];
}> => {
  // 1. Get parsed accounts for all vaults
  const parsedAccounts = await connection.getMultipleParsedAccounts(vaultPairs.flat(), { commitment: "confirmed" });

  // 2. Create a vault -> token mint/amount mapping
  const vaultTokenMap = new Map(
    parsedAccounts.value.map((account, i) => {
      const key = vaultPairs.flat()[i]?.toString();
      const info = (account?.data as ParsedAccountData | undefined)?.parsed.info as ParsedTokenBalanceInfo | undefined;
      return [key, info];
    }),
  );

  // 3. Get unique token mints
  const uniqueTokenMints = Array.from(new Set(Array.from(vaultTokenMap.values()).map((info) => info?.mint))).filter(
    (mint) => mint !== undefined,
  );

  // 4. Fetch token metadata for all unique token mints
  const tokensMetadata = await getTokensMetadata(helius, uniqueTokenMints);

  // 5. Process swaps and calculate prices in one pass
  const priceData = swaps
    .map((swap) => {
      const vaultAInfo = vaultTokenMap.get(swap.vaultA.toString());
      const vaultBInfo = vaultTokenMap.get(swap.vaultB.toString());
      return { ...calculatePrice(vaultAInfo, vaultBInfo), timestamp: swap.timestamp, swap: swap.args };
    })
    .filter((data) => !!data.mint) as PriceData[];

  return { tokensMetadata, priceData };
};

const getTokensMetadata = async (helius: Helius, mints: string[]): Promise<TokenMetadata[]> => {
  const tokensData = await helius.rpc.getAssetBatch({ ids: mints });
  return tokensData.map((data) => {
    const metadata = data.content?.metadata;
    const tokenInfo = data.token_info;
    const imageUri = data.content?.files?.[0]?.cdn_uri ?? data.content?.files?.[0]?.uri ?? data.content?.links?.image;

    return {
      mint: data.id,
      metadata: {
        name: metadata?.name,
        symbol: metadata?.symbol,
        description: metadata?.description,
        imageUri,
      },
      mintBurnt: !tokenInfo?.mint_authority,
      freezeBurnt: !tokenInfo?.freeze_authority,
      supply: tokenInfo?.supply,
      isPumpToken: data.authorities?.some((authority) => authority.address === PUMP_FUN_AUTHORITY.toString()),
    };
  });
};

const calculatePrice = (
  vaultAInfo: ParsedTokenBalanceInfo | undefined,
  vaultBInfo: ParsedTokenBalanceInfo | undefined,
) => {
  if (!vaultAInfo || !vaultBInfo) return;

  // Separate Wrapped SOL (if it's present) and token swapped against WSOL
  const wrappedSolInfo =
    vaultAInfo.mint === WRAPPED_SOL_MINT.toString()
      ? vaultAInfo
      : vaultBInfo.mint === WRAPPED_SOL_MINT.toString()
        ? vaultBInfo
        : undefined;
  if (!wrappedSolInfo) return;
  const tokenInfo = wrappedSolInfo === vaultAInfo ? vaultBInfo : vaultAInfo;

  const tokenPrice =
    // If there is no token in the pool, we can consider the price to be 0
    // This happens with tokens with no or close to 0 liquidity, or super botted,
    // e.g. ECMYTGjvXWR3mb5RFEh3F1mAqFBe5EEe53A2n1F1sbpg or 5Jng6jkLKU1o8BNrCzTEMXMFvPjNJZTpdWR3Hq4RHJb6 (for reference)
    tokenInfo.tokenAmount.amount === "0"
      ? 0
      : Number(
          (BigInt(wrappedSolInfo.tokenAmount.amount) *
            BigInt(PRICE_PRECISION) *
            BigInt(10 ** tokenInfo.tokenAmount.decimals)) /
            (BigInt(tokenInfo.tokenAmount.amount) * BigInt(10 ** wrappedSolInfo.tokenAmount.decimals)),
        );

  return {
    mint: tokenInfo.mint,
    price: tokenPrice,
    decimals: tokenInfo.tokenAmount.decimals,
  };
};
