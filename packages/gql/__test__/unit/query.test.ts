import { beforeAll, describe, expect, it } from "vitest";

import { createClient, GqlClient } from "../../src/index";
import { createWallet } from "../lib/common";

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

describe("materialized view comparison tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({
      url: "http://localhost:8090/v1/graphql",
      hasuraAdminSecret: "password",
    });

    const refreshRes = await gql.db.RefreshTokenRollingStats30MinMutation();
    if (refreshRes.error || !refreshRes.data?.api_refresh_token_rolling_stats_30min?.success)
      throw new Error("Error refreshing token rolling stats");
  });

  it("should return same data for GetTopTokensByVolume", async () => {
    const startOld = performance.now();
    const oldResult = await gql.db.GetTopTokensByVolumeCachedQuery({
      interval: "30m",
      recentInterval: "1m",
    });
    const endOld = performance.now();

    const startNew = performance.now();
    const newResult = await gql.db.GetTopTokensByVolumeQuery_new({});
    const endNew = performance.now();

    console.log(`Old query took: ${endOld - startOld}ms`);
    console.log(`New query took: ${endNew - startNew}ms`);

    expect(newResult.data?.api_token_rolling_stats_30min.map((t) => t.mint)).toEqual(
      oldResult.data?.token_stats_interval_cache.map((t) => t.token_mint),
    );
  });

  it("should return same data for GetBulkTokenLiveData", async () => {
    const tokens = (await gql.db.GetTopTokensByVolumeQuery_new({})).data?.api_token_rolling_stats_30min.map(
      (t) => t.mint,
    );
    if (!tokens || tokens.some((t) => t === null)) throw new Error("No tokens found");

    const startOld = performance.now();
    // @ts-expect-error a single token cannot be null
    const oldResult = await gql.db.GetBulkTokenLiveDataQuery({ tokens });
    const endOld = performance.now();

    const startNew = performance.now();
    // @ts-expect-error a single token cannot be null
    const newResult = await gql.db.GetBulkTokenLiveDataQuery_new({ tokens });
    const endNew = performance.now();

    console.log(`Old query took: ${endOld - startOld}ms`);
    console.log(`New query took: ${endNew - startNew}ms`);

    expect(
      newResult.data?.api_token_rolling_stats_30min
        .sort((a, b) => a.mint!.localeCompare(b.mint!))
        .map((t) => ({
          mint: t.mint,
          latest_price_usd: t.latest_price_usd,
          volume_usd_30m: t.volume_usd_30m,
          trades_30m: t.trades_30m,
          price_change_pct_30m: t.price_change_pct_30m,
          volume_usd_1m: t.volume_usd_1m,
          trades_1m: t.trades_1m,
          price_change_pct_1m: t.price_change_pct_1m,
          supply: t.supply,
        })),
    ).toEqual(
      oldResult.data?.token_stats_interval_cache
        .sort((a, b) => a.token_mint!.localeCompare(b.token_mint!))
        .map((t) => ({
          mint: t.token_mint,
          latest_price_usd: t.latest_price_usd,
          volume_usd_30m: t.total_volume_usd,
          trades_30m: t.total_trades,
          price_change_pct_30m: t.price_change_pct,
          volume_usd_1m: t.recent_volume_usd,
          trades_1m: t.recent_trades,
          price_change_pct_1m: t.recent_price_change_pct,
          supply: t.token_metadata_supply,
        })),
    );
  });

  it("should return same data for GetTokenLiveData", async () => {
    const tokens = (await gql.db.GetTopTokensByVolumeQuery_new({})).data?.api_token_rolling_stats_30min.map(
      (t) => t.mint,
    );
    if (!tokens || !tokens[0]) throw new Error("No tokens found");

    const startOld = performance.now();
    const oldResult = await gql.db.GetTokenLiveDataQuery({ token: tokens[0] });
    const endOld = performance.now();

    const startNew = performance.now();
    const newResult = await gql.db.GetTokenLiveDataQuery_new({ token: tokens[0] });
    const endNew = performance.now();

    console.log(`Old query took: ${endOld - startOld}ms`);
    console.log(`New query took: ${endNew - startNew}ms`);

    const newResultData = newResult.data?.api_token_rolling_stats_30min[0];
    const oldResultData = oldResult.data?.token_stats_interval_cache[0];
    expect({
      mint: newResultData?.mint,
      latest_price_usd: newResultData?.latest_price_usd,
      volume_usd_30m: newResultData?.volume_usd_30m,
      trades_30m: newResultData?.trades_30m,
      price_change_pct_30m: newResultData?.price_change_pct_30m,
      volume_usd_1m: newResultData?.volume_usd_1m,
      trades_1m: newResultData?.trades_1m,
      price_change_pct_1m: newResultData?.price_change_pct_1m,
      supply: newResultData?.supply,
    }).toEqual({
      mint: oldResultData?.token_mint,
      latest_price_usd: oldResultData?.latest_price_usd,
      volume_usd_30m: oldResultData?.total_volume_usd,
      trades_30m: oldResultData?.total_trades,
      price_change_pct_30m: oldResultData?.price_change_pct,
      volume_usd_1m: oldResultData?.recent_volume_usd,
      trades_1m: oldResultData?.recent_trades,
      price_change_pct_1m: oldResultData?.recent_price_change_pct,
      supply: oldResultData?.token_metadata_supply,
    });
  });

  it("should return same data for GetBulkTokenMetadata", async () => {
    const tokens = (await gql.db.GetTopTokensByVolumeQuery_new({})).data?.api_token_rolling_stats_30min.map(
      (t) => t.mint,
    );
    if (!tokens || tokens.some((t) => t === null)) throw new Error("No tokens found");

    const startOld = performance.now();
    const oldResult = await gql.db.GetBulkTokenMetadataQuery({ tokens });
    const endOld = performance.now();

    const startNew = performance.now();
    // @ts-expect-error a single token cannot be null
    const newResult = await gql.db.GetBulkTokenMetadataQuery_new({ tokens });
    const endNew = performance.now();

    console.log(`Old query took: ${endOld - startOld}ms`);
    console.log(`New query took: ${endNew - startNew}ms`);

    expect(
      newResult.data?.api_token_rolling_stats_30min
        .sort((a, b) => a.mint!.localeCompare(b.mint!))
        .map((t) => ({
          mint: t.mint,
          name: t.name,
          symbol: t.symbol,
          image_uri: t.image_uri,
          supply: t.supply,
          decimals: t.decimals,
          description: t.description,
          external_url: t.external_url,
          is_pump_token: t.is_pump_token,
        })),
    ).toEqual(
      oldResult.data?.token_metadata_formatted
        .sort((a, b) => a.mint!.localeCompare(b.mint!))
        .map((t) => ({
          mint: t.mint,
          name: t.name,
          symbol: t.symbol,
          image_uri: t.image_uri,
          supply: t.supply,
          decimals: t.decimals,
          description: t.description,
          external_url: t.external_url,
          is_pump_token: t.is_pump_token,
        })),
    );
  });

  it("should return same data for GetTokenMetadata", async () => {
    const tokens = (await gql.db.GetTopTokensByVolumeQuery_new({})).data?.api_token_rolling_stats_30min.map(
      (t) => t.mint,
    );
    if (!tokens || !tokens[0]) throw new Error("No tokens found");

    const startOld = performance.now();
    const oldResult = await gql.db.GetBulkTokenMetadataQuery({ tokens: [tokens[0]] });
    const endOld = performance.now();

    const startNew = performance.now();
    const newResult = await gql.db.GetTokenMetadataQuery_new({ token: tokens[0] });
    const endNew = performance.now();

    console.log(`Old query took: ${endOld - startOld}ms`);
    console.log(`New query took: ${endNew - startNew}ms`);

    const newResultData = newResult.data?.api_token_rolling_stats_30min[0];
    const oldResultData = oldResult.data?.token_metadata_formatted[0];
    expect({
      mint: newResultData?.mint,
      name: newResultData?.name,
      symbol: newResultData?.symbol,
      image_uri: newResultData?.image_uri,
      supply: newResultData?.supply,
      decimals: newResultData?.decimals,
      description: newResultData?.description,
      external_url: newResultData?.external_url,
      is_pump_token: newResultData?.is_pump_token,
    }).toEqual({
      mint: oldResultData?.mint,
      name: oldResultData?.name,
      symbol: oldResultData?.symbol,
      image_uri: oldResultData?.image_uri,
      supply: oldResultData?.supply,
      decimals: oldResultData?.decimals,
      description: oldResultData?.description,
      external_url: oldResultData?.external_url,
      is_pump_token: oldResultData?.is_pump_token,
    });
  });
});
