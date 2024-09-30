#!/usr/bin/env node
import { createServerClient } from "@tub/gql";
import { config } from "dotenv";
import { parseEther } from "viem";
import { parseEnv } from "../bin/parseEnv";

config({ path: "../../.env" });

const env = parseEnv();

const UPDATE_INTERVAL = 1_000;
const VOLATILITY = 0.2;
const PRECISION = 1e9;

// https://stackoverflow.com/questions/8597731/are-there-known-techniques-to-generate-realistic-looking-fake-stock-data
const getRandomPriceChange = () => {
  const random = Math.random();
  let changePercent = random * VOLATILITY * 2;
  if (changePercent > VOLATILITY) changePercent -= 2 * VOLATILITY;
  return 1 + changePercent;
};

export const start = async () => {
  try {
    const gql = await createServerClient({ url: env.GRAPHQL_URL, hasuraAdminSecret: env.HASURA_ADMIN_SECRET });
    gql.GetLatestTokensSubscription({ limit: 10 }).subscribe(async (data) => {
      const updatePrices = async () => {
        const priceUpdates = data.data?.token?.map(async (token) => {
          const tokenId = token.id;
          const _tokenPrice = await gql.GetLatestTokenPriceQuery({ tokenId });

          const currentPrice = BigInt(_tokenPrice.data?.token_price_history[0]?.price ?? parseEther("1", "gwei"));
          const priceChange = getRandomPriceChange();
          const tokenPrice = (currentPrice * BigInt(Math.floor(priceChange * PRECISION))) / BigInt(PRECISION);

          return {
            token: tokenId,
            symbol: token.symbol,
            price: tokenPrice.toString(),
          };
        });

        const allPriceUpdates = await Promise.all(priceUpdates ?? []);
        await gql.AddManyTokenPriceHistoryMutation({
          objects: allPriceUpdates.map(({ token, price }) => ({
            token,
            price,
          })),
        });

        console.log(`Updated prices for ${allPriceUpdates.length} tokens`);
        allPriceUpdates.forEach(({ symbol, price }) => {
          console.log(`New price for ${symbol}: ${price}`);
        });

        await new Promise((resolve) => setTimeout(resolve, UPDATE_INTERVAL));
      };

      while (true) await updatePrices();
    });
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
