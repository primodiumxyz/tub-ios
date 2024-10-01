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

export const getPoolTokenPrice = async ({
  poolCoin,
  poolPc,
}: SwapAccounts): Promise<Omit<PriceData, "slot"> | undefined> => {
  const poolCoinInfo = await connection.getParsedAccountInfo(poolCoin, {
    commitment: "confirmed",
  });
  const poolPcInfo = await connection.getParsedAccountInfo(poolPc, {
    commitment: "confirmed",
  });

  const poolCoinInfoParsed = (poolCoinInfo.value?.data as ParsedAccountData | undefined)?.parsed.info;
  const poolPcInfoParsed = (poolPcInfo.value?.data as ParsedAccountData | undefined)?.parsed.info;

  if (!(poolCoinInfoParsed?.mint === WRAPPED_SOL_MINT.toString()) || !poolPcInfoParsed) return;

  const tokenPrice = poolCoinInfoParsed.tokenAmount.uiAmount / poolPcInfoParsed.tokenAmount.uiAmount;
  return { mint: poolPcInfoParsed.mint, price: tokenPrice };
};
