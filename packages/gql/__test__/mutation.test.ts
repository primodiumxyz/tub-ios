import { beforeAll, describe, expect, it } from "vitest";
import { createClient, GqlClient } from "../src/index"

const token_id = "722e8490-e852-4298-a250-7b0a399fec57";

describe("mutation tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to create a new user", async () => {
    const result = await gql.db.RegisterNewUserMutation({ amount: "1000000000000000000", username: "test_user" });
    expect(result.data?.insert_account_one?.id).toBeDefined();
  });

  it("should be able to buy and sell tokens", async () => {
    const result = await gql.db.RegisterNewUserMutation({ amount: "200", username: "test_user" });
    expect(result.data?.insert_account_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "200",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(sell_result.data?.sell_token?.id).toBeDefined();

    const balance = (await gql.db.GetAccountBalanceQuery({ account: result.data?.insert_account_one?.id! })).data?.balance[0].value;

    expect(balance).toEqual(100);
  });

  it("should have the correct token balance", async () => {
    const result = await gql.db.RegisterNewUserMutation({ amount: "200", username: "test_user" });
    expect(result.data?.insert_account_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "150",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(sell_result.data?.sell_token?.id).toBeDefined();

    const balance = (await gql.db.GetAccountTokenBalanceQuery({ account: result.data?.insert_account_one?.id!, token: token_id })).data?.balance[0].value;

    expect(balance).toEqual(50);
  });

  it("should fail to buy if the user doesn't have enough balance", async () => {
    const result = await gql.db.RegisterNewUserMutation({ amount: "100", username: "test_user" });
    expect(result.data?.insert_account_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "200",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(buy_result.error).toBeDefined();
  });

  it("should fail to sell if the user doesn't have token balance", async () => {
    const result = await gql.db.RegisterNewUserMutation({ amount: "200", username: "test_user" });
    expect(result.data?.insert_account_one?.id).toBeDefined();

    const buy_result = await gql.db.BuyTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "100",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(buy_result.data?.buy_token?.id).toBeDefined();

    const sell_result = await gql.db.SellTokenMutation({
      account: result.data?.insert_account_one?.id!,
      amount: "150",
      override_token_price: "1000000000",
      token: token_id
    })

    expect(sell_result.error).toBeDefined();
  });
});
