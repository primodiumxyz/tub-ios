#!/usr/bin/env node
import { createServerClient } from "@tub/gql";
import { config } from "dotenv";
import { parseEther } from "viem";
import { parseEnv } from "../bin/parseEnv";
import random_price_changes from "./random_price_changes.json";

config({ path: "../../.env" });

const env = parseEnv();

type PriceHistory = {
  index: number;
  delayMs: number;
  priceChange: number;
};

type PumpTrendRange = {
  start: number;
  end: number;
};

type RandomPriceChanges = {
  priceHistory: PriceHistory[];
  pumpTrendRanges: PumpTrendRange[];
};

const { priceHistory: PRICE_HISTORY, pumpTrendRanges: PUMP_TREND_RANGES } = random_price_changes as RandomPriceChanges;
const SPEED_FACTOR = 1;
const PRECISION = 10 ** 18;

const getPriceHistoryIterator = (startIndex?: number) => {
  let randomPriceHistoryIndex = 0;
  if (startIndex === undefined) {
    const randomPumpTrend = PUMP_TREND_RANGES[Math.floor(Math.random() * PUMP_TREND_RANGES.length)]!;
    randomPriceHistoryIndex = Math.floor(Math.random() * (randomPumpTrend.end - randomPumpTrend.start));
  } else {
    randomPriceHistoryIndex = startIndex;
  }

  const next = () => {
    randomPriceHistoryIndex = (randomPriceHistoryIndex + 1) % PRICE_HISTORY.length;
    return PRICE_HISTORY[randomPriceHistoryIndex]!;
  };

  return { next };
};

export const start = async () => {
  try {
    const gql = createServerClient({ url: env.GRAPHQL_URL, hasuraAdminSecret: env.HASURA_ADMIN_SECRET });
    // Remember indexes for when the tokens array changes
    const currentPriceHistoryIndexes = new Map<string, number>();

    // TODO: listen to latest tokens
    const _latestTokens = await gql.GetAllTokensQuery();
    const latestTokens = _latestTokens.data?.token;

    latestTokens?.forEach(async (token) => {
      const tokenId = token.id;
      // Either get a random entry from the price history, or start again at the current index if the token
      // was already in the array
      const lastIndex = currentPriceHistoryIndexes.get(tokenId);
      const { next } = getPriceHistoryIterator(lastIndex);

      const _tokenPrice = await gql.GetLatestTokenPriceQuery({ tokenId });
      let tokenPrice = BigInt(_tokenPrice.data?.token_price_history[0]?.price ?? parseEther("1", "gwei"));

      const update = async () => {
        const historyData = next();

        tokenPrice = (tokenPrice * BigInt(historyData.priceChange * PRECISION)) / BigInt(PRECISION);
        await gql.AddTokenPriceHistoryMutation({ token: tokenId, price: tokenPrice.toString() });
        console.log(
          "Price updated for token",
          token.name,
          "change",
          historyData.priceChange.toFixed(2),
          "new price",
          tokenPrice.toString(),
        );

        await new Promise((resolve) => setTimeout(resolve, historyData.delayMs / SPEED_FACTOR));
      };

      while (true) await update();
    });
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
