// #!/usr/bin/env node
import Client, { CommitmentLevel, SubscribeRequest, SubscribeUpdate } from "@triton-one/yellowstone-grpc";
import { config } from "dotenv";

import { createClient as createGqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { BatchManager } from "@/lib/batch-manager";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";
import { connection, ixParser, txFormatter } from "@/lib/setup";
import { decodeSwapInfo } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ----------------------------- HANDLE UPDATES ----------------------------- */
const handleSubscribeUpdate = async (data: SubscribeUpdate, batchManager: BatchManager) => {
  try {
    // Parse the transaction and retrieve the swapped token accounts
    const timestamp = Date.now();
    if (!data.transaction) return;
    const tx = txFormatter.formTransactionFromJson(data.transaction, timestamp);
    if (!tx) return;

    const txsWithParsedIxs = ixParser.parseTransactionWithInnerInstructions(tx);
    const swapInfo = decodeSwapInfo(txsWithParsedIxs, timestamp);
    await batchManager.add(swapInfo);
  } catch (error) {
    console.error("Unexpected error in handleSubscribeUpdate:", error);
  }
};

/* ------------------------------- SETUP GEYSER ------------------------------ */
const setupGeyserClient = async (batchManager: BatchManager, connectionId: string) => {
  return new Promise((_, reject) => {
    // @ts-expect-error This is a known issue; see https://github.com/rpcpool/yellowstone-grpc/issues/428
    const client = new Client.default(`${env.QUICKNODE_ENDPOINT}:10000`, env.QUICKNODE_TOKEN, {});

    client
      .subscribe()
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      .then((stream: any) => {
        stream.on("error", (error: unknown) => {
          console.error(`[${connectionId}] Stream error:`, error);
          stream.end();
          reject(error);
        });

        stream.on("end", () => {
          console.log(`[${connectionId}] Stream ended`);
          reject(new Error("Stream ended"));
        });

        stream.on("data", async (data: SubscribeUpdate) => {
          await handleSubscribeUpdate(data, batchManager);
        });

        const request: SubscribeRequest = {
          slots: { client: { filterByCommitment: true } },
          transactions: {
            client: {
              vote: false,
              failed: false,
              signature: undefined,
              accountInclude: [RaydiumAmmParser.PROGRAM_ID.toString()],
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
      })
      .catch(reject);
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

      const batchManager = new BatchManager(gql, connection);
      await setupGeyserClient(batchManager, connectionId);
    } catch (err) {
      console.warn(`[${connectionId}] Error in indexer, restarting in a second...`);
      console.error(err);
      await new Promise((resolve) => setTimeout(resolve, 1_000));
    }
  }
};
