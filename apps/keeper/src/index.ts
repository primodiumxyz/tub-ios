#!/usr/bin/env node
import "dotenv/config";
import { parseEnv } from "../bin/parseEnv";
import { createServerClient } from "@tub/gql";
import { parseEther } from 'viem'
import random_price_history from "./random_price_changes.json"

const env = parseEnv();

type PriceHistory = {
  index: number;
  delay: number;
  priceChange: number;
}

type RandomPriceHistory = {
  priceHistory: PriceHistory[];
}

const price_history = (random_price_history as RandomPriceHistory).priceHistory;

export const start = async () => {
  try {
    const gql = createServerClient({ url: env.GRAPHQL_URL, hasuraAdminSecret: env.HASURA_ADMIN_SECRET });

    const account = await gql.RegisterNewUserMutation({
      username: `keeper-${Math.floor(Math.random() * 1001) }`,
      amount: parseEther("420").toString()
    });

    const accountId = account.data?.insert_account_one?.id;

    if (!accountId) {
      throw new Error("Failed to create account");
    }

    // const _tokenPrice = await gql.GetLatestTokenPriceQuery({
    //   tokenId: env.TARGET_TOKEN
    // });

    const tokenPrice = parseEther("1");
    let index =  Math.floor(Math.random() * price_history.length);
    let currentPrice = tokenPrice;
    let tokenCount = 0;
    while (true) {
      const price = price_history[index % price_history.length]!;

      const newPrice = currentPrice * BigInt(Math.floor(price.priceChange * 1000000000))/ 1000000000n;

      console.log(price.priceChange);
      
      if(price.priceChange > 1) {
        await gql.BuyTokenMutation({
          amount: "1",
          token: env.TARGET_TOKEN,
          account: accountId,
          override_token_price: newPrice.toString()
        })
        console.log("Bought token at", currentPrice);
        tokenCount++;
      }
      else if(tokenCount > 0) {
        await gql.SellTokenMutation({
          amount: "1",
          token: env.TARGET_TOKEN,
          account: accountId,
          override_token_price: newPrice.toString()
        })
        console.log("Sold token at", currentPrice);
        tokenCount--;
      }

      index++;
      currentPrice = newPrice;

      // wait for the delay
      await new Promise(resolve => setTimeout(resolve, price.delay));
    }
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

