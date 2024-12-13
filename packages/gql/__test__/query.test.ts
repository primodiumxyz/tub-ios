import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to query the transactions of a wallet", async () => {
    const wallet = createWallet();

    const purchase_result = await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "200",
      token_price_usd: "0.001",
      user_wallet: wallet,
      user_agent: "test",
    });

    expect(purchase_result.data?.insert_token_purchase_one?.id).toBeDefined();

    const sale_result = await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "100",
      token_price_usd: "0.002",
      user_wallet: wallet,
      user_agent: "test",
    });

    expect(sale_result.data?.insert_token_sale_one?.id).toBeDefined();

    const transactions = (await gql.db.GetWalletTransactionsQuery({ wallet: wallet })).data?.transactions;

    expect(transactions?.length).toEqual(2);
    expect(transactions?.[0].token_mint).toEqual(tokenAddress);
    expect(transactions?.[0].token_amount).toEqual(-100);
    expect(transactions?.[0].token_price_usd).toEqual(0.002);
    expect(transactions?.[0].token_value_usd).toEqual(-100 * 0.002);
    expect(transactions?.[1].token_mint).toEqual(tokenAddress);
    expect(transactions?.[1].token_amount).toEqual(200);
    expect(transactions?.[1].token_value_usd).toEqual(200 * 0.001);
  });

  it("should correctly calculate total trade value", async () => {
    const testWallet = createWallet();
    const timestamp = new Date().toISOString();

    // Create multiple transactions
    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "100",
      token_price_usd: "0.001",
      user_wallet: testWallet,
      user_agent: "test",
    });

    await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "50",
      token_price_usd: "0.002",
      user_wallet: testWallet,
      user_agent: "test",
    });

    const result = await gql.db.GetTotalTradeValueQuery({
      wallet: testWallet,
      mint: tokenAddress,
      since: new Date(timestamp),
    });

    // Expected: (100 * 0.001) + (-50 * 0.002) = 0.1 - 0.1 = 0
    expect(result.data?.transactions_aggregate.aggregate?.sum?.token_value_usd).toEqual(0);
  });

  it("should fetch only the latest token purchase", async () => {
    const testWallet = createWallet();

    // Create multiple transactions in sequence
    await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "50",
      token_price_usd: "0.002",
      user_wallet: testWallet,
      user_agent: "test",
    });

    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "100",
      token_price_usd: "0.001",
      user_wallet: testWallet,
      user_agent: "test",
    });

    // This should be the one returned (most recent purchase)
    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "200",
      token_price_usd: "0.003",
      user_wallet: testWallet,
      user_agent: "test",
    });

    const result = await gql.db.GetLatestTokenPurchaseQuery({
      wallet: testWallet,
      mint: tokenAddress,
    });

    const latestPurchase = result.data?.transactions[0];
    expect(latestPurchase).toBeDefined();
    expect(latestPurchase?.token_mint).toEqual(tokenAddress);
    expect(latestPurchase?.token_amount).toEqual(200);
    expect(latestPurchase?.token_price_usd).toEqual(0.003);
    expect(latestPurchase?.token_value_usd).toEqual(200 * 0.003);
  });
});
