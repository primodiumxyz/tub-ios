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
      error_details: "test error",
    });

    expect(sale_result.data?.insert_token_sale_one?.id).toBeDefined();

    const transactions = (await gql.db.GetWalletTransactionsQuery({ wallet: wallet })).data?.transactions;

    expect(transactions?.length).toEqual(2);
    expect(transactions?.[0].token_mint).toEqual(tokenAddress);
    expect(transactions?.[0].token_amount).toEqual(-100);
    expect(transactions?.[0].token_price_usd).toEqual(0.002);
    expect(transactions?.[0].success).toEqual(false);

    expect(transactions?.[1].token_mint).toEqual(tokenAddress);
    expect(transactions?.[1].token_amount).toEqual(200);
    expect(transactions?.[1].token_price_usd).toEqual(0.001);
    expect(transactions?.[1].success).toEqual(true);
  });
});
