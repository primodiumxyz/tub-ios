// #!/usr/bin/env node
import { Logs } from "@solana/web3.js";
import { config } from "dotenv";
import { WebSocket } from "ws";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { PRICE_DATA_BATCH_SIZE, PRICE_PRECISION } from "@/lib/constants";
import { decodeSwapAccounts } from "@/lib/decoders";
import { connection, ixParser } from "@/lib/setup";
import { PriceData } from "@/lib/types";
import { filterLogs, getPoolTokenPrice } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ------------------------------ PROCESS LOGS ------------------------------ */
const processLogs = async ({ err, signature }: Logs): Promise<(PriceData | undefined)[]> => {
  if (err) return [];
  // Fetch and format the transaction
  const tx = await connection.getTransaction(signature, {
    commitment: "confirmed",
    maxSupportedTransactionVersion: 0,
  });
  if (!tx || tx.meta?.err) return [];
  // Parse the transaction and retrieve the swapped token accounts
  const parsedIxs = ixParser.parseTransactionWithInnerInstructions(tx);
  const swapAccountsArray = decodeSwapAccounts(tx, parsedIxs);
  if (swapAccountsArray.length === 0) return [];

  return await Promise.all(swapAccountsArray.map((swapAccounts) => getPoolTokenPrice(swapAccounts)));
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
export const start = async () => {
  try {
    const gql = (await createGqlClient({ url: env.GRAPHQL_URL, hasuraAdminSecret: env.HASURA_ADMIN_SECRET })).db;
    const ws = new WebSocket(env.HELIUS_WS_URL);

    setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ method: "ping" }));
        console.log("Ping sent");
      }
    }, 30_000);
    ws.onclose = () => console.log("WebSocket connection closed");
    ws.onerror = (error) => console.log("WebSocket error:", error);
    ws.onopen = () => {
      console.log("WebSocket connection opened");
      ws.send(
        JSON.stringify(
          {
            jsonrpc: "2.0",
            id: 1,
            method: "logsSubscribe",
            params: ["all"],
          },
          // TODO: needs min. Helius business plan
          // {
          //     jsonrpc: "2.0",
          //     id: 420,
          //     method: "transactionSubscribe",
          //     params: [
          //         {   failed: false,
          //             accountInclude: [RaydiumAmmParser.PROGRAM_ID.toString()]
          //         },
          //         {
          //             commitment: "confirmed",
          //             encoding: "jsonParsed",
          //             transactionDetails: "full",
          //             maxSupportedTransactionVersion: 0
          //         }
          //     ]
          // }
        ),
      );
    };
    ws.onmessage = (event) => {
      // Parse
      const obj = JSON.parse(event.data.toString());
      const data = obj.params?.result.value as Logs | undefined;
      const logs = data?.logs;
      // later when we directly filter on the subscription, we can remove this
      const filteredLogs = logs ? filterLogs(logs) : undefined;
      // Process
      if (data && filteredLogs) processLogs(data).then((priceData) => handlePriceData(gql, priceData));
    };
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
