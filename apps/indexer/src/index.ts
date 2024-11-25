// #!/usr/bin/env node
import Client, { CommitmentLevel, SubscribeRequest, SubscribeUpdate } from "@triton-one/yellowstone-grpc";
import { config } from "dotenv";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { PUMP_FUN_PROGRAM } from "@/lib/constants";
import { ixParser, txFormatter } from "@/lib/setup";
import { decodeSwapInfo, fetchPriceData, upsertTrades } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ----------------------------- HANDLE UPDATES ----------------------------- */
const handleSubscribeUpdate = async (data: SubscribeUpdate, gql: GqlClient["db"]) => {
  try {
    // Parse the transaction and retrieve the swapped token accounts
    const timestamp = Date.now();
    if (!data.transaction) return;
    const tx = txFormatter.formTransactionFromJson(data.transaction, timestamp);
    if (!tx) return;

    const parsedIxs = ixParser.parseTransactionWithInnerInstructions(tx);
    const swapInfo = decodeSwapInfo(parsedIxs, timestamp);
    const swapWithPriceData = await fetchPriceData(swapInfo);
    await upsertTrades(gql, swapWithPriceData);
  } catch (error) {
    console.error("Unexpected error in handleSubscribeUpdate:", error);
  }
};

/* ------------------------------- SETUP GEYSER ------------------------------ */
const setupGeyserClient = async (gql: GqlClient["db"], connectionId: string) => {
  return new Promise(async (_, reject) => {
    const client = new Client(env.QUICKNODE_ENDPOINT, env.QUICKNODE_TOKEN, {});
    const stream = await client.subscribe();

    stream.on("error", (error) => {
      console.error(`[${connectionId}] Stream error:`, error);
      stream.end();
      reject(error);
    });

    stream.on("end", () => {
      console.log(`[${connectionId}] Stream ended`);
      reject(new Error("Stream ended"));
    });

    stream.on("data", async (data: SubscribeUpdate) => {
      await handleSubscribeUpdate(data, gql);
    });

    const request: SubscribeRequest = {
      slots: { client: { filterByCommitment: true } },
      transactions: {
        client: {
          vote: false,
          failed: false,
          signature: undefined,
          accountInclude: [PUMP_FUN_PROGRAM.toString()],
          accountExclude: [],
          accountRequired: [],
        },
      },
      commitment: CommitmentLevel.CONFIRMED,
      accounts: {},
      transactionsStatus: {},
      entry: {},
      blocks: {},
      blocksMeta: {},
      accountsDataSlice: [],
      ping: undefined,
    };

    stream.write(request, (err: unknown) => {
      if (err) {
        console.error(`[${connectionId}] Error sending subscription request:`, err);
        stream.end();
        reject(err);
        return;
      }

      console.log(`[${connectionId}] Subscription started at ${new Date().toISOString()}`);
    });
  });
};

/* --------------------------------- START --------------------------------- */
let currentConnectionId = 0;
export const start = async () => {
  while (true) {
    const connectionId = `conn_${++currentConnectionId}`;

    try {
      console.log(`[${connectionId}] Starting new Geyser connection`);

      const gql = (
        await createGqlClient({
          url: env.NODE_ENV !== "production" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
          hasuraAdminSecret: env.NODE_ENV !== "production" ? "password" : env.HASURA_ADMIN_SECRET,
        })
      ).db;

      await setupGeyserClient(gql, connectionId);
    } catch (err) {
      console.warn(`[${connectionId}] Error in indexer, restarting in a second...`);
      console.error(err);
      await new Promise((resolve) => setTimeout(resolve, 1_000));
    }
  }
};
