#!/usr/bin/env node
import { createClient as createGqlClient } from "@tub/gql";
import { config } from "dotenv";
import { parseEther } from "viem";
import { parseEnv } from "../bin/parseEnv";

config({ path: "../../.env" });

const env = parseEnv();

const PRECISION = 1e9;
const VOLATILITY = 0.1;
const BASE_PUMP_CHANCE = 0.075;
const BASE_DUMP_CHANCE = 0.075;
const MIN_PRICE_THRESHOLD = parseEther("0.1", "gwei");
const MAX_PRICE_THRESHOLD = parseEther("2.5", "gwei");

// Generates a random price change with potential for pumps and dumps
function getRandomPriceChange(currentPrice: bigint): number {
  const rand = Math.random();
  let changeFactor = 0;

  // Calculate adjusted pump and dump chances based on current price
  const pumpChance = BASE_PUMP_CHANCE * (currentPrice < MIN_PRICE_THRESHOLD ? 3 : 1);
  const dumpChance = BASE_DUMP_CHANCE * (currentPrice > MAX_PRICE_THRESHOLD ? 3 : 1);

  if (rand < pumpChance) {
    changeFactor = Math.random() * 0.2 + 0.10;
  } else if (rand < pumpChance + dumpChance) {
    changeFactor = -(Math.random() * 0.2 + 0.10);
  } else {
    changeFactor = (Math.random() - 0.5) * 2 * VOLATILITY;
  }

  return 1 + changeFactor;
}

const url = env.NODE_ENV === "production" ? env.GRAPHQL_URL : "http://localhost:8080/v1/graphql";
const secret = env.NODE_ENV === "production" ? env.HASURA_ADMIN_SECRET : "password";

export const _start = async () => {
  try {
    const gql = (
      await createGqlClient({
        url,
        hasuraAdminSecret: secret,
      })
    ).db;

    gql.GetLatestMockTokensSubscription({ limit: 10 }).subscribe(async (data) => {
      const updatePrices = async () => {
        const priceUpdates = data.data?.token?.map(async (token) => {
          const tokenId = token.id;
          const _tokenPrice = await gql.GetLatestTokenPriceQuery({
            tokenId
          }, {
            requestPolicy: "network-only",
          });

          const currentPrice = BigInt(_tokenPrice.data?.token_price_history[0]?.price ?? parseEther("1", "gwei"));
          console.log("Current price:", currentPrice);
          const priceChange = getRandomPriceChange(currentPrice);
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

        await new Promise((resolve) => setTimeout(resolve, Math.random() * 1000 + 250));
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

      const response = await fetch(url.split("/v1")[0] + "/healthz?strict=true", {
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        console.log("Hasura service is healthy");
        // wait for 5 seconds for seeding to complete if retry count is more than 1
        if (i > 0) {
          await new Promise((resolve) => setTimeout(resolve, 10_000));
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
