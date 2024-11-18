import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("mutation tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to airdrop to wallet", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "1000000000000000000", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();
  });

  it("should be able to buy and sell tokens", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "200", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      wallet: wallet,
      amount: "200",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      wallet: wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(sell_result.data?.sell_token?.id).toBeDefined();

    const balance = (await gql.db.GetWalletTokenBalanceQuery({ wallet: wallet, token: tokenAddress })).data?.balance[0]
      .value;

    expect(balance).toEqual(100);
  });

  it("should have the correct token balance", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "200", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      wallet: wallet,
      amount: "150",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      wallet: wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(sell_result.data?.sell_token?.id).toBeDefined();

    const balance = (await gql.db.GetWalletTokenBalanceQuery({ wallet: wallet, token: tokenAddress })).data?.balance[0]
      .value;

    expect(balance).toEqual(50);
  });

  it("should fail to buy if the user doesn't have enough balance", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "100", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      wallet: wallet,
      amount: "200",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(buy_result.error).toBeDefined();
  });

  it("should fail to sell if the user doesn't have token balance", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "200", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      wallet: wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      wallet: wallet,
      amount: "150",
      token_price: "1000000000",
      token: tokenAddress,
    });

    expect(sell_result.error).toBeDefined();
  });
});
