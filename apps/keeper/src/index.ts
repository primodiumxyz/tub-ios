#!/usr/bin/env node
import { createClient as createGqlClient } from "@tub/gql";
import { config } from "dotenv";
import { parseEther } from "viem";
import { parseEnv } from "../bin/parseEnv";

config({ path: "../../.env" });

const env = parseEnv();

const UPDATE_INTERVAL = 1_000;
const VOLATILITY = 0.075;
const PRECISION = 1e9;


const tokenState = new Map<string, { direction: number; duration: number }>(); // Store direction and duration for each token

const getRandomPriceChange = (tokenId: string, currentPrice: bigint) => {
  if (!tokenState.has(tokenId)) {
    tokenState.set(tokenId, {
      direction: 1,
      duration: Math.floor(Math.random() * 10) + 1,
    });
  }

  const tokenInfo = tokenState.get(tokenId)!;

  if (tokenInfo.duration <= 0) {
    tokenInfo.direction = Math.random() < 0.5 ? 1 : -1;
    tokenInfo.duration = Math.floor(Math.random() * 10) + 1; // New random duration
  }

  // Macro price change based on direction
  let macroChange = Math.random() * VOLATILITY;
  macroChange *= tokenInfo.direction;

  // Add small random noise that can go either up or down
  const noise = (Math.random() - 0.5) * VOLATILITY * 0.5;

  // Combine macro direction change with noise
  let totalChange = macroChange + noise;

  // Check if the current price is less than 0.5 and give it a 50% chance of doubling
  if (currentPrice < parseEther("0.25", "gwei") && Math.random() < 0.5) {
    totalChange = 2;
  }

  tokenInfo.duration--;

  tokenState.set(tokenId, tokenInfo);

  return 1 + totalChange;
};

const url = env.NODE_ENV === "prod" ? env.GRAPHQL_URL : "http://localhost:8080/v1/graphql";
const secret = env.NODE_ENV === "prod" ? env.HASURA_ADMIN_SECRET : "password";

export const _start = async () => {
  try {
    const gql = (
      await createGqlClient({
        url: env.NODE_ENV === "prod" ? env.GRAPHQL_URL : "http://localhost:8080/v1/graphql",
        hasuraAdminSecret: env.NODE_ENV === "prod" ? env.HASURA_ADMIN_SECRET : "password",
      })
    ).db;
    gql.GetLatestMockTokensSubscription({ limit: 10 }).subscribe(async (data) => {
      const updatePrices = async () => {
        const priceUpdates = data.data?.token?.map(async (token) => {
          const tokenId = token.id;
          const _tokenPrice = await gql.GetLatestTokenPriceQuery({ tokenId });

          const currentPrice = BigInt(_tokenPrice.data?.token_price_history[0]?.price ?? parseEther("1", "gwei"));
          const priceChange = getRandomPriceChange(tokenId, currentPrice);
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
          console.log(`Old price : New price for ${symbol}: ${price}`);
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
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        console.log("Hasura service is healthy");
        // wait for 5 seconds for seeding to complete if retry count is more than 1
        if (i > 0) {
          await new Promise((resolve) => setTimeout(resolve, 5000));
        }
        return _start();
      }
    } catch (error) {
      console.warn(`Attempt ${i + 1}/${maxAttempts}: Hasura service is not reachable yet. Retrying...`);
    }

    if (i < maxAttempts - 1) {
      await new Promise((resolve) => setTimeout(resolve, retryInterval));
    }
  }

  throw new Error("Hasura service is not available. Please ensure it's running with `pnpm hasura-up` and try again.");
};
