import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to get the balance of the account before and after a buy executed", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "100", wallet: wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    await new Promise((resolve) => setTimeout(resolve, 1000));

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    const balance_before = await gql.db.GetWalletBalanceIgnoreIntervalQuery({ wallet, interval: "500ms" });

    expect(balance_before.data?.balance[0].value).toBe(100);

    const balance_after = await gql.db.GetWalletBalanceQuery({ wallet });

    expect(balance_after.data?.balance[0].value).toBe(0);
  });

  it("should be able to get the account token balance between intervals", async () => {
    const wallet = createWallet();
    const result = await gql.db.AirdropNativeToWalletMutation({ amount: "200", wallet });
    expect(result.data?.insert_wallet_transaction_one?.id).toBeDefined();

    await gql.db.BuyTokenMutation({
      wallet,
      amount: "100",
      token_price: "1000000000",
      token: tokenAddress,
    });

    const balance_before = await gql.db.GetWalletTokenBalanceIgnoreIntervalQuery({
      token: tokenAddress,
      wallet,
      interval: "100ms",
    });

    expect(balance_before.data?.balance[0].value).toBe(0);

    const balance_after = await gql.db.GetWalletTokenBalanceQuery({ token: tokenAddress, wallet });

    expect(balance_after.data?.balance[0].value).toBe(100);
  });
});
