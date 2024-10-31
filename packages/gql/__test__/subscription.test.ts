import { beforeAll, describe, expect, it } from "vitest";
import { createClient, GqlClient } from "../src/index"

const token_id = "722e8490-e852-4298-a250-7b0a399fec57";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });


  it("it should be able to subscribe to the account balance", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    let balance: number = 100;
    gql.db.GetAccountBalanceSubscription({ account: user.data?.insert_account_one?.id! }).subscribe(data => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(100);

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(0);
  });

  it("it should be able to subscribe to the account balance before and after a transaction", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    await new Promise((resolve) => setTimeout(resolve, 1000));

    let balance: number = 100;
    let balanceBefore: number = 100;

    const subBalanceBefore = gql.db.GetAccountBalanceIgnoreIntervalSubscription({ account: user.data?.insert_account_one?.id!, interval: "500ms" }).subscribe(data => {
      balanceBefore = Number(data.data?.balance[0].value);
    });

    const subBalance = gql.db.GetAccountBalanceSubscription({ account: user.data?.insert_account_one?.id! }).subscribe(data => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(100);
    expect(balanceBefore).toBe(100);

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(0);
    expect(balanceBefore).toBe(100);

    subBalanceBefore.unsubscribe();
    subBalance.unsubscribe();
  });

  it("it should be able to subscribe to the account token balance", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    let balance: number = 0;
    const subBalance = gql.db.GetAccountTokenBalanceSubscription({ token: token_id, account: user.data?.insert_account_one?.id! }).subscribe(data => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(0);

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(100);

    subBalance.unsubscribe();
  });

  it("it should be able to subscribe to the account token balance before and after a transaction", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    let balance: number = 0;
    let balanceBefore: number = 0;

    const subBalanceBefore = gql.db.GetAccountTokenBalanceIgnoreIntervalSubscription({ token: token_id, account: user.data?.insert_account_one?.id!, interval: "1s" }).subscribe(data => {
      balanceBefore = Number(data.data?.balance[0].value);
    });

    const subBalance = gql.db.GetAccountTokenBalanceSubscription({ token: token_id, account: user.data?.insert_account_one?.id! }).subscribe(data => {
      balance = Number(data.data?.balance[0].value);
    });

    expect(balance).toBe(0);
    expect(balanceBefore).toBe(0);

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    await new Promise((resolve) => setTimeout(resolve, 500));

    expect(balance).toBe(100);
    expect(balanceBefore).toBe(0);

    subBalanceBefore.unsubscribe();
    subBalance.unsubscribe();
  });

});