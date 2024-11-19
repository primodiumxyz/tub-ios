import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("it should be able to subscribe to the wallet balance", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "100", wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    let balance: number = 100;
    gql.db.GetWalletBalanceSubscription({ wallet }).subscribe((data) => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(100);

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(0);
  });

  it("it should be able to subscribe to the wallet balance before and after a transaction", async () => {
    const wallet = createWallet();

    // use array to store balances to also test the order of the values and prevent race conditions
    let balance: number[] = [];
    let balanceBefore: number[] = [];

    const subBalanceBefore = gql.db
      .GetWalletBalanceIgnoreIntervalSubscription({ wallet, interval: "2000ms" })
      .subscribe((data) => {
        balanceBefore.push(Number(data.data?.balance[0].value));
      });

    const subBalance = gql.db.GetWalletBalanceSubscription({ wallet }).subscribe((data) => {
      balance.push(Number(data.data?.balance[0].value));
    });

    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "100", wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();
    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toEqual([100]);
    expect(balanceBefore).toEqual([0]);

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toEqual([100, 0]);
    expect(balanceBefore).toEqual([0]);

    subBalanceBefore.unsubscribe();
    subBalance.unsubscribe();
  });

  it("it should be able to subscribe to the wallet token balance", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "200", wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    let balance: number = 0;
    const subBalance = gql.db.GetWalletTokenBalanceSubscription({ token: tokenAddress, wallet }).subscribe((data) => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(0);

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    // wait for the values to be updated from subscription
    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(100);

    subBalance.unsubscribe();
  });

  it("it should be able to subscribe to the token balance before and after a transaction", async () => {
    const wallet = createWallet();

    // use array to store balances to also test the order of the values and prevent race conditions
    let balance: number[] = [];
    let balanceBefore: number[] = [];

    const subBalanceBefore = gql.db
      .GetWalletTokenBalanceIgnoreIntervalSubscription({ token: tokenAddress, wallet, interval: "2s" })
      .subscribe((data) => {
        balanceBefore.push(Number(data.data?.balance[0].value));
      });

    const subBalance = gql.db.GetWalletTokenBalanceSubscription({ token: tokenAddress, wallet }).subscribe((data) => {
      balance.push(Number(data.data?.balance[0].value));
    });

    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "100", wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    // wait for the values to be updated from subscription
    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toEqual([0]);
    expect(balanceBefore).toEqual([0]);

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toEqual([0, 100]);
    expect(balanceBefore).toEqual([0]);

    subBalanceBefore.unsubscribe();
    subBalance.unsubscribe();
  });
});
