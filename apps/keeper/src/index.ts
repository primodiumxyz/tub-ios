#!/usr/bin/env node
import "dotenv/config";
import { parseEnv } from "../bin/parseEnv";
import { createServerClient } from "@tub/gql";
import { parseEther } from 'viem'
import random_price_history from "./random_price_changes.json"

const env = parseEnv();

type PriceHistory = {
  index: number;
  delayMs: number;
  priceChange: number;
}

type RandomPriceHistory = {
  priceHistory: PriceHistory[];
}

const SPEED_FACTOR = 1;
const USE_PRICE_HISTORY = false;
const TARGET_TOKEN = "e9e2d8a1-0b57-4b9b-9949-a790de9b24ae";

const price_history = (random_price_history as RandomPriceHistory).priceHistory;

//https://stackoverflow.com/questions/8597731/are-there-known-techniques-to-generate-realistic-looking-fake-stock-data
const getRandomPrice = (volatility: number) => {
  const random = Math.random();
  let changePercent = random * volatility * 2;

  if(changePercent > volatility) {
    changePercent -= (2*volatility);
  }

  const delay = Math.floor(Math.random() * 900) + 100;

  return {
    priceChange: 1 + changePercent,
    delayMs: delay
  };
}

export const start = async () => {
  try {
    const gql = createServerClient({ url: env.GRAPHQL_URL, hasuraAdminSecret: env.HASURA_ADMIN_SECRET });

    const _tokenPrice = await gql.GetLatestTokenPriceQuery({
      tokenId: TARGET_TOKEN
    });

    const tokenPrice = BigInt(_tokenPrice.data?.token_price_history[0]?.price ?? parseEther("1", "gwei"));
    let index =  Math.floor(Math.random() * price_history.length);
    let currentPrice = tokenPrice;
    while (true) {
      const price = USE_PRICE_HISTORY ? price_history[index % price_history.length]! : getRandomPrice(0.2);
      
      const newPrice = currentPrice * BigInt(Math.floor(price.priceChange * 1000000000))/ 1000000000n;

      await gql.AddTokenPriceHistoryMutation({
        token: TARGET_TOKEN,
        price: newPrice.toString()
      })

      console.log("New price", newPrice, "change", price.priceChange);

      currentPrice = newPrice;
      index++;

      // wait for the delay
      await new Promise(resolve => setTimeout(resolve, price.delayMs/SPEED_FACTOR));
    }
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

