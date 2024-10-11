// #!/usr/bin/env node
import { config } from "dotenv";
import { WebSocket } from "ws";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { PRICE_DATA_BATCH_SIZE, PRICE_PRECISION, PROGRAMS } from "@/lib/constants";
import { connection, ixParser, txFormatter } from "@/lib/setup";
import { PriceData, TransactionSubscriptionResult } from "@/lib/types";
import { decodeSwapAccounts, getPoolTokenPrice } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ------------------------------ PROCESS LOGS ------------------------------ */
const processLogs = async (result: TransactionSubscriptionResult): Promise<(PriceData | undefined)[]> => {
  try {
    // Parse the transaction and retrieve the swapped token accounts
    const tx = txFormatter.formTransactionFromJson(result, Date.now());
    // We will process parsed data, if it comes from known programs (e.g. system, spl-token, spl-memo)
    // In such cases, it won't include the fields "data" or "accounts", and we're not interested anyway
    if (!tx) return [];

    const parsedIxs = ixParser.parseParsedTransactionWithInnerInstructions(tx);
    const swapAccountsArray = decodeSwapAccounts(parsedIxs);
    if (swapAccountsArray.length === 0) return [];

    return await Promise.all(swapAccountsArray.map((swapAccounts) => getPoolTokenPrice(connection, swapAccounts)));
  } catch (error) {
    console.error("Unexpected error in processLogs:", error);
    return [];
  }
};

/* ------------------------------- HANDLE DATA ------------------------------ */
let priceDataBatch: PriceData[] = [];
const handlePriceData = async (gql: GqlClient["db"], priceData: (PriceData | undefined)[]) => {
  const validPriceData = priceData.filter((data) => data !== undefined);
  if (!validPriceData.length) return;
  priceDataBatch.push(...validPriceData);

  if (priceDataBatch.length >= PRICE_DATA_BATCH_SIZE) {
    const _priceDataBatch = priceDataBatch;
    priceDataBatch = [];

    try {
      // 1. Insert new tokens
      const insertRes = await gql.RegisterManyNewTokensMutation({
        objects: _priceDataBatch.map(({ mint, platform }) => ({
          mint,
          name: platform, // TODO: temporary
          symbol: "",
          supply: "0",
        })),
      });

      if (insertRes.error) {
        console.error("Error in RegisterManyNewTokensMutation:", insertRes.error.message);
        return;
      }
      console.log(`Inserted ${insertRes.data?.insert_token?.affected_rows} new tokens`);

      // 2. Fetch all tokens ids (both new and existing)
      const mints = _priceDataBatch.map(({ mint }) => mint);
      const fetchRes = await gql.GetTokensByMintsQuery({ mints });
      if (fetchRes.error) {
        console.error("Error in GetTokensByMintsQuery:", fetchRes.error.message);
        return;
      }

      const tokenMap = new Map(fetchRes.data?.token.map((token) => [token.mint, token.id]));
      const validPriceData = _priceDataBatch.filter(({ mint }) => tokenMap.has(mint));
      if (validPriceData.length !== _priceDataBatch.length) {
        console.warn(`${_priceDataBatch.length - validPriceData.length} tokens were not found`);
      }

      // 3. Add price history
      const addPriceHistoryRes = await gql.AddManyTokenPriceHistoryMutation({
        objects: validPriceData.map(({ mint, price }) => ({
          token: tokenMap.get(mint)!,
          price: (price * PRICE_PRECISION).toString(),
        })),
      });

      if (addPriceHistoryRes.error) {
        console.error("Error in AddManyTokenPriceHistoryMutation:", addPriceHistoryRes.error.message);
      } else {
        console.log(`Saved ${validPriceData.length} price data points`);
      }
    } catch (error) {
      console.error("Unexpected error in handlePriceData:", error);
    }
  }
};

/* -------------------------------- WEBSOCKET ------------------------------- */
const setup = (gql: GqlClient["db"]) => {
  const ws = new WebSocket(env.HELIUS_GEYSER_WS_URL);

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
    if (result) processLogs(result).then((priceData) => handlePriceData(gql, priceData));
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
        url: env.NODE_ENV !== "prod" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
        hasuraAdminSecret: env.NODE_ENV !== "prod" ? "password" : env.HASURA_ADMIN_SECRET,
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
