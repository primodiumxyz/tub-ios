// #!/usr/bin/env node
import { config } from "dotenv";
import { WebSocket } from "ws";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { getRandomTokenMetadata } from "@/lib/_random";
import { FETCH_PRICE_BATCH_SIZE, PROGRAMS, WRITE_GQL_BATCH_SIZE } from "@/lib/constants";
import { connection, ixParser, txFormatter } from "@/lib/setup";
import { PriceData, SwapAccounts, TransactionSubscriptionResult } from "@/lib/types";
import { decodeSwapAccounts, getPoolTokenPriceMultiple } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ------------------------------ PROCESS LOGS ------------------------------ */
const processLogs = (result: TransactionSubscriptionResult): SwapAccounts[] => {
  try {
    // Parse the transaction and retrieve the swapped token accounts
    const timestamp = Date.now();
    const tx = txFormatter.formTransactionFromJson(result, timestamp);

    const parsedIxs = ixParser.parseParsedTransactionWithInnerInstructions(tx);
    return decodeSwapAccounts(parsedIxs, timestamp);
  } catch (error) {
    console.error("Unexpected error in processLogs:", error);
    return [];
  }
};

/* ------------------------------- HANDLE DATA ------------------------------ */
let swapAccountsBatch: SwapAccounts[] = [];
let priceDataBatch: PriceData[] = [];

const handleSwapData = async (gql: GqlClient["db"], swapAccountsArray: SwapAccounts[]) => {
  // Add swap data to batch and continue only if the batch is filled enough
  if (swapAccountsArray.length === 0) return;
  swapAccountsBatch.push(...swapAccountsArray);
  if (swapAccountsBatch.length < FETCH_PRICE_BATCH_SIZE) return;

  // Fetch price data out of swap accounts, add it and continue only if the second batch is filled enough
  const _swapAccountsBatch = swapAccountsBatch.slice(0, FETCH_PRICE_BATCH_SIZE);
  try {
    // clear the batch before the async call so it isn't included in the next batch
    swapAccountsBatch = swapAccountsBatch.slice(FETCH_PRICE_BATCH_SIZE);
    const priceData = await getPoolTokenPriceMultiple(connection, _swapAccountsBatch);
    priceDataBatch.push(...priceData);
  } catch (err) {
    console.error("Unexpected error in getPoolTokenPriceMultiple:", err);
    // readd the failed batch so it can be retried in the next iteration
    swapAccountsBatch.push(..._swapAccountsBatch);
  }

  if (priceDataBatch.length < WRITE_GQL_BATCH_SIZE) return;
  const _priceDataBatch = priceDataBatch;
  // clear the batch before all async calls for the same reason as above
  priceDataBatch = [];

  try {
    // 1. Insert new tokens
    const insertRes = await gql.RegisterManyNewTokensMutation({
      objects: _priceDataBatch.map(({ mint, platform, timestamp }) => ({
        // TODO: temporary until we know when to fetch & write actual token metadata
        ...getRandomTokenMetadata(),
        mint,
        platform: platform,
      })),
    });

    if (insertRes.error) {
      console.error("Error in RegisterManyNewTokensMutation:", insertRes.error.message);
      priceDataBatch.push(..._priceDataBatch);
      return;
    }
    console.log(`Inserted ${insertRes.data?.insert_token?.affected_rows} new tokens`);

    // 2. Fetch all tokens ids (both new and existing)
    const mints = _priceDataBatch.map(({ mint }) => mint);
    const fetchRes = await gql.GetTokensByMintsQuery({ mints });
    if (fetchRes.error) {
      console.error("Error in GetTokensByMintsQuery:", fetchRes.error.message);
      priceDataBatch.push(..._priceDataBatch);
      return;
    }

    const tokenMap = new Map(fetchRes.data?.token.map((token) => [token.mint, token.id]));
    const validPriceData = _priceDataBatch.filter(({ mint }) => tokenMap.has(mint));
    if (validPriceData.length !== _priceDataBatch.length) {
      console.error(`${_priceDataBatch.length - validPriceData.length} tokens were not found`);
      priceDataBatch.push(..._priceDataBatch);
      return;
    }

    // 3. Add price history
    const addPriceHistoryRes = await gql.AddManyTokenPriceHistoryMutation({
      objects: validPriceData.map(({ mint, price, timestamp }) => ({
        token: tokenMap.get(mint)!,
        price: price.toString(),
        created_at: new Date(timestamp),
      })),
    });

    if (addPriceHistoryRes.error) {
      console.error("Error in AddManyTokenPriceHistoryMutation:", addPriceHistoryRes.error.message);
      priceDataBatch.push(..._priceDataBatch);
      return;
    }

    console.log(`Saved ${validPriceData.length} price data points`);
  } catch (err) {
    console.error("Unexpected error in handleSwapData:", err);
  }
};

/* -------------------------------- WEBSOCKET ------------------------------- */
const setup = (gql: GqlClient["db"]) => {
  const ws = new WebSocket(`wss://atlas-mainnet.helius-rpc.com/?api-key=${env.HELIUS_API_KEY}`);

  ws.onclose = () => {
    console.log("WebSocket connection closed, attempting to reconnect...");
    setTimeout(() => setup(gql), 5000);
  };
  ws.onerror = (error) => {
    console.log("WebSocket error:", error);
    ws.close(); // This will trigger onclose and attempt to reconnect
  };
  ws.onopen = () => {
    console.log("WebSocket connection opened");
    ws.send(
      JSON.stringify({
        jsonrpc: "2.0",
        id: 420,
        method: "transactionSubscribe",
        params: [
          { failed: false, accountInclude: Object.values(PROGRAMS).map((p) => p.publicKey.toString()) },
          {
            commitment: "confirmed",
            encoding: "jsonParsed",
            transactionDetails: "full",
            maxSupportedTransactionVersion: 0,
          },
        ],
      }),
    );
  };
  ws.onmessage = (event) => {
    // Parse
    const obj = JSON.parse(event.data.toString());
    const result = obj.params?.result as TransactionSubscriptionResult | undefined;
    if (result) {
      const swapAccounts = processLogs(result);
      handleSwapData(gql, swapAccounts);
    }
  };

  setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.ping();
      console.log("Ping sent");
    }
  }, 60_000);
};

export const start = async () => {
  try {
    const gql = (
      await createGqlClient({
        url: env.NODE_ENV !== "production" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
        hasuraAdminSecret: env.NODE_ENV !== "production" ? "password" : env.HASURA_ADMIN_SECRET,
      })
    ).db;
    setup(gql);
  } catch (err) {
    console.warn("Error in indexer, restarting in 5 seconds...");
    console.error(err);
    await new Promise((resolve) => setTimeout(resolve, 5000));
    start(); // recursive call to restart if there's an unhandled error
  }
};
