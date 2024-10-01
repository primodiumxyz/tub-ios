#!/usr/bin/env node
import { Logs } from "@solana/web3.js";
import { config } from "dotenv";

import { createClient as createGqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { RAYDIUM_PUBLIC_KEY } from "@/lib/constants";
import { decodeRaydiumTx } from "@/lib/raydium";
import { connection, ixParser, txFormatter } from "@/lib/setup";
import { PriceData } from "@/lib/types";
import { filterLogs, getPoolTokenPrice } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

// TODO: fix "Parser does not matching the instruction args": what does this mean/why does this happen/is this an issue?
// see https://github.com/Shyft-to/solana-tx-parser-public/blob/26a605855c1f7f17bdf61f4dcbc78df286be84ea/src/parsers.ts#L1548

/* ------------------------------ PROCESS LOGS ------------------------------ */
const processLogs = async ({ err, signature }: Logs): Promise<PriceData | undefined> => {
  if (err) return;

  // Fetch and format the transaction
  const tx = await connection.getTransaction(signature, {
    commitment: "confirmed",
    maxSupportedTransactionVersion: 0,
  });
  if (!tx || tx.meta?.err) return;
  const formattedTx = txFormatter.formTransactionFromJson(tx, Date.now());

  // Parse the transaction and retrieve the swapped token accounts
  const parsedIxs = ixParser.parseTransactionWithInnerInstructions(tx);

  // Raydium
  const raydiumProgramIxs = parsedIxs.filter((ix) => ix.programId.equals(RAYDIUM_PUBLIC_KEY));

  const swapAccounts = raydiumProgramIxs.length ? decodeRaydiumTx(formattedTx, raydiumProgramIxs) : undefined;
  if (!swapAccounts) return;

  const tokenPrice = await getPoolTokenPrice(swapAccounts);
  return tokenPrice;
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
      const obj = JSON.parse(event.data);
      const data = obj.params?.result.value as Logs | undefined;
      const logs = data?.logs;
      const filteredLogs = logs ? filterLogs(logs) : undefined;

      // Process
      if (data && filteredLogs) {
        processLogs(data).then((priceData) => {
          if (!priceData) return;
          // TODO: save to DB
          console.log(priceData);
        });
      }
    };
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
