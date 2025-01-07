import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8090/v1/graphql", hasuraAdminSecret: "password" });
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

  it("should correctly calculate PnL for a wallet's token transactions", async () => {
    const testWallet = createWallet();

    // Create a purchase transaction
    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "100",
      token_price_usd: "1.00", // Buy 100 tokens at $1.00 each
      user_wallet: testWallet,
      user_agent: "test",
    });

    // Create a sale transaction
    await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "50",
      token_price_usd: "2.00", // Sell 50 tokens at $2.00 each
      user_wallet: testWallet,
      user_agent: "test",
    });

    const result = await gql.db.GetWalletTokenPnlQuery({
      wallet: testWallet,
      token_mint: tokenAddress,
    });

    // Calculate expected PnL:
    // Purchase: -100 tokens * $1.00 = -$100
    // Sale: 50 tokens * $2.00 = +$100
    // Total PnL = $0
    expect(result.data?.transactions_value_aggregate[0]?.total_value_usd).toEqual(0);
  });

  it("should handle multiple purchases and sales for PnL calculation", async () => {
    const testWallet = createWallet();

    // Multiple transactions to test aggregation
    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "100",
      token_price_usd: "1.00",
      user_wallet: testWallet,
      user_agent: "test",
    });

    await gql.db.AddTokenPurchaseMutation({
      token_mint: tokenAddress,
      token_amount: "50",
      token_price_usd: "1.50",
      user_wallet: testWallet,
      user_agent: "test",
    });

    await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "75",
      token_price_usd: "2.00",
      user_wallet: testWallet,
      user_agent: "test",
    });

    await gql.db.AddTokenSaleMutation({
      token_mint: "0x0000000000000000000000000000000000000000",
      token_amount: "75",
      token_price_usd: "2.00",
      user_wallet: testWallet,
      user_agent: "test",
    });
    await gql.db.AddTokenSaleMutation({
      token_mint: tokenAddress,
      token_amount: "75",
      token_price_usd: "2.00",
      user_wallet: "0x0000000000000000000000000000000000000000",
      user_agent: "test",
    });

    const result = await gql.db.GetWalletTokenPnlQuery({
      wallet: testWallet,
      token_mint: tokenAddress,
    });

    // Calculate expected PnL:
    // Purchase 1: 100 tokens * $1.00 = $100
    // Purchase 2: 50 tokens * $1.50 = $75
    // Sale: 75 tokens * $2.00 = $150
    // Total PnL = $25
    expect(result.data?.transactions_value_aggregate.length).toEqual(1);
    expect(result.data?.transactions_value_aggregate[0]?.total_value_usd).toEqual(25);
  });

  it("should return zero for wallet with no transactions", async () => {
    const emptyWallet = createWallet();

    const result = await gql.db.GetWalletTokenPnlQuery({
      wallet: emptyWallet,
      token_mint: tokenAddress,
    });

    expect(result.data?.transactions_value_aggregate.length).toEqual(0);
    expect(result.data?.transactions_value_aggregate[0]?.total_value_usd).toBeUndefined();
  });
});
