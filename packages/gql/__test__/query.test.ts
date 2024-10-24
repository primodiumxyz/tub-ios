import { beforeAll, describe, expect, it } from "vitest";
import { createClient, GqlClient } from "../src/index"

const token_id = "722e8490-e852-4298-a250-7b0a399fec57";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to get all accounts", async () => {
    const result = await gql.db.GetAllAccountsQuery();

    expect(result.data?.account).toBeInstanceOf(Array);
    expect(result.data?.account.length).toBeGreaterThan(0);
  });

  it("should be able to get the balance of the account before and after a buy executed", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    await new Promise((resolve) => setTimeout(resolve, 1000));

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    const balance_before = await gql.db.GetAccountBalanceIgnoreIntervalQuery({ account: user.data?.insert_account_one?.id!, interval: "100ms" });

    expect(balance_before.data?.balance[0].value).toBe(100);

    const balance_after = await gql.db.GetAccountBalanceQuery({ account: user.data?.insert_account_one?.id! });

    expect(balance_after.data?.balance[0].value).toBe(0);
  });

  it("should be able to get the account token balance between intervals", async () => {
    const user = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });

    await gql.db.BuyTokenMutation({
      account: user.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    const balance_before = await gql.db.GetAccountTokenBalanceIgnoreIntervalQuery({ token: token_id, account: user.data?.insert_account_one?.id!, interval: "100ms" });

    expect(balance_before.data?.balance[0].value).toBe(0);

    const balance_after = await gql.db.GetAccountTokenBalanceQuery({ token: token_id, account: user.data?.insert_account_one?.id! });

    expect(balance_after.data?.balance[0].value).toBe(100);
  });

  it("should be able to get the token price history between intervals", async () => {
    await new Promise((resolve) => setTimeout(resolve, 500));

    const result = await gql.db.AddTokenPriceHistoryMutation({
      price: "123456789",
      token: token_id
    })

    const history = await gql.db.GetTokenPriceHistoryIntervalQuery({ token: token_id, interval: "100ms" });

    const history_2 = await gql.db.GetTokenPriceHistoryIgnoreIntervalQuery({ token: token_id, interval: "0s" });

    //test if history with 100ms is correct
    expect(history.data?.token_price_history_offset.length).toEqual(1);
    //test should contain more than 1
    expect(history_2.data?.token_price_history_offset.length).toBeGreaterThan(1);
  });
});
