// #!/usr/bin/env node
import { Logs } from "@solana/web3.js";
import { config } from "dotenv";
import { WebSocket } from "ws";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { PRICE_DATA_BATCH_SIZE, RAYDIUM_PUBLIC_KEY } from "@/lib/constants";
import { decodeRaydiumTx } from "@/lib/raydium";
import { connection, ixParser, txFormatter } from "@/lib/setup";
import { PriceData } from "@/lib/types";
import { filterLogs, getPoolTokenPrice } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ------------------------------ PROCESS LOGS ------------------------------ */
const processLogs = async ({ err, signature }: Logs): Promise<PriceData | undefined> => {
  if (err) return;
  // Fetch and format the transaction
  const tx = await connection.getTransaction(signature, {
    commitment: "confirmed",
    maxSupportedTransactionVersion: 0,
  });
  if (!tx || tx.meta?.err) return;
  // const formattedTx = txFormatter.formTransactionFromJson(tx, Date.now());
  // Parse the transaction and retrieve the swapped token accounts
  const parsedIxs = ixParser.parseTransactionWithInnerInstructions(tx);

  // Raydium
  const raydiumProgramIxs = parsedIxs.filter((ix) => ix.programId.equals(RAYDIUM_PUBLIC_KEY));
  const swapAccounts = raydiumProgramIxs.length ? decodeRaydiumTx(tx, raydiumProgramIxs) : undefined;
  if (!swapAccounts) return;

  const tokenPrice = await getPoolTokenPrice(swapAccounts);
  return tokenPrice;
};

/* ------------------------------- HANDLE DATA ------------------------------ */
let priceDataBatch: PriceData[] = [];
const handlePriceData = async (gql: GqlClient["db"], priceData: PriceData | undefined) => {
  if (!priceData) return;
  priceDataBatch.push(priceData);

  if (priceDataBatch.length === PRICE_DATA_BATCH_SIZE) {
    const data = priceDataBatch;
    priceDataBatch = [];

    await gql.AddManyTokenPriceHistoryMutation({
      objects: data.map(({ mint, price }) => ({
        token: mint,
        price: price.toString(),
      })),
    });

    console.log(`Saved ${data.length} price data points`);
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
      const filteredLogs = logs ? filterLogs(logs) : undefined;
      // Process
      if (data && filteredLogs) processLogs(data).then((priceData) => handlePriceData(gql, priceData));
    };
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
