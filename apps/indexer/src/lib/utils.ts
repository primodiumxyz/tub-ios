import { GetVersionedBlockConfig } from "@solana/web3.js";

import { LOG_FILTERS, WRAPPED_SOL_MINT } from "@/lib/constants";
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
