#!/usr/bin/env node
import { createClient as createGqlClient } from "@tub/gql";
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

const url = env.NODE_ENV === "prod" ? env.GRAPHQL_URL : "http://localhost:8080/v1/graphql";
const secret = env.NODE_ENV === "prod" ? env.HASURA_ADMIN_SECRET : "password";

export const _start = async () => {
  try {
    const gql = (await createGqlClient({ url, hasuraAdminSecret: secret })).db;
    gql.GetLatestMockTokensSubscription({ limit: 10 }).subscribe(async (data) => {
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

export const start = async () => {
  const maxAttempts = 20;
  const retryInterval = 5000; // 1 second
  const timeout = 5000; // 5 seconds

  for (let i = 0; i < maxAttempts; i++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      const response = await fetch(url, {
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        console.log('Hasura service is healthy');
        // wait for 5 seconds for seeding to complete if retry count is more than 1
        if (i > 0) {
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
        return _start();
      }
    } catch (error) {
      console.warn(`Attempt ${i + 1}/${maxAttempts}: Hasura service is not reachable yet. Retrying...`);
    }

    if (i < maxAttempts - 1) {
      await new Promise(resolve => setTimeout(resolve, retryInterval));
    }
  }

  throw new Error('Hasura service is not available. Please ensure it\'s running with `pnpm hasura-up` and try again.');
}