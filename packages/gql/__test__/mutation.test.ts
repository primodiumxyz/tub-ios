import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../src/index";
import { createWallet } from "./lib/common";

const tokenAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL";

describe("mutation tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to record token purchases and sales", async () => {
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
  });
});
