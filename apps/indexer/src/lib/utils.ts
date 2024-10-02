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
  const [poolCoinRes, poolPcRes] = (
    await connection.getMultipleParsedAccounts([poolCoin, poolPc], {
      commitment: "confirmed",
    })
  ).value;

  const poolCoinData = poolCoinRes?.data as ParsedAccountData | Buffer | undefined;
  const poolPcData = poolPcRes?.data as ParsedAccountData | Buffer | undefined;

  if (poolCoinData instanceof Buffer || poolPcData instanceof Buffer) {
    console.log("buffer");
    return { buffer: true };
  }

  const poolCoinParsedInfo = poolCoinData?.parsed.info;
  const poolPcParsedInfo = poolPcData?.parsed.info;

  if (
    !(poolCoinParsedInfo?.mint === WRAPPED_SOL_MINT.toString()) ||
    !poolPcParsedInfo?.mint ||
    !poolCoinParsedInfo?.tokenAmount?.uiAmount ||
    !poolPcParsedInfo?.tokenAmount?.uiAmount
  )
    return;

  const tokenPrice = poolCoinParsedInfo.tokenAmount.uiAmount / poolPcParsedInfo.tokenAmount.uiAmount;
  return { mint: poolPcParsedInfo.mint, price: tokenPrice };
};
