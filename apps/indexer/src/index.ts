// #!/usr/bin/env node
import { PublicKey } from "@solana/web3.js";
import { config } from "dotenv";
import { WebSocket } from "ws";

import { createClient as createGqlClient, GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { CLOSE_CODES, FETCH_DATA_BATCH_SIZE, FETCH_HELIUS_WRITE_GQL_BATCH_SIZE } from "@/lib/constants";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";
import { connection, helius, ixParser, txFormatter } from "@/lib/setup";
import { PriceData, Swap, SwapType, TokenMetadata, TransactionSubscriptionResult } from "@/lib/types";
import { decodeSwapData, processVaultsData } from "@/lib/utils";

config({ path: "../../.env" });

const env = parseEnv();

/* ------------------------------ PROCESS LOGS ------------------------------ */
const handleLogs = <T extends SwapType = SwapType>(result: TransactionSubscriptionResult): Swap<T>[] => {
  try {
    // Parse the transaction and retrieve the swapped token accounts
    const timestamp = Date.now();
    const tx = txFormatter.formTransactionFromJson(result, timestamp);

    const parsedIxs = ixParser.parseParsedTransactionWithInnerInstructions(tx);
    return decodeSwapData(parsedIxs, timestamp);
  } catch (error) {
    console.error("Unexpected error in handleLogs:", error);
    return [];
  }
};

/* ------------------------------- HANDLE DATA ------------------------------ */
let swapsBatch: Swap<SwapType>[] = []; // batch of swaps we need to process
let uniqueVaultPairsBatch: PublicKey[][] = []; // batch of unique vault pairs inside `swapsBatch` we need to fetch metadata and price for
let tokensDataBatch: TokenMetadata[] = []; // tokens metadata we need to save to the DB
let priceDataBatch: PriceData[] = []; // price data based on swaps we need to save to the DB

// TODO: Problem here is that since we fetch prices in batches, when we get the price of a token for a trade, the price will be too recent.
// Meaning that the price at this timestamp will be wrong, as well as the volume.
// An easy fix is to reduce the batch size, a good one would be to fetch the price at the timestamp of the trade with some archival node.
const handleSwapData = async <T extends SwapType = SwapType>(gql: GqlClient["db"], swaps: Swap<T>[]) => {
  // Add swap data to batch and continue only if the batch is filled enough
  if (swaps.length === 0) return;
  swapsBatch.push(...swaps);
  // Aggregate unique vault pairs associated with the swaps
  uniqueVaultPairsBatch.push(
    ...Array.from(new Set(swaps.map(({ vaultA, vaultB }) => (vaultA < vaultB ? [vaultA, vaultB] : [vaultB, vaultA])))),
  );
  if (uniqueVaultPairsBatch.length < FETCH_DATA_BATCH_SIZE) return;

  // Fetch metadata and price data for a batch of tokens, and get the swaps related to these tokens
  const _uniqueVaultPairsBatch = uniqueVaultPairsBatch.slice(0, FETCH_DATA_BATCH_SIZE);
  const _swapsBatch = swapsBatch.filter(({ vaultA, vaultB }) =>
    _uniqueVaultPairsBatch.some(
      ([_vaultA, _vaultB]) =>
        (_vaultA?.equals(vaultA) && _vaultB?.equals(vaultB)) || (_vaultA?.equals(vaultB) && _vaultB?.equals(vaultA)),
    ),
  );
  try {
    // clear the batch before the async call so it isn't included in the next batch
    uniqueVaultPairsBatch = uniqueVaultPairsBatch.slice(FETCH_DATA_BATCH_SIZE);
    swapsBatch = swapsBatch.filter(
      ({ vaultA, vaultB }) =>
        !_uniqueVaultPairsBatch.some(
          ([_vaultA, _vaultB]) =>
            (_vaultA?.equals(vaultA) && _vaultB?.equals(vaultB)) ||
            (_vaultA?.equals(vaultB) && _vaultB?.equals(vaultA)),
        ),
    );

    const { tokensMetadata, priceData } = await processVaultsData(
      connection,
      helius,
      _uniqueVaultPairsBatch,
      _swapsBatch,
    );
    tokensDataBatch.push(...tokensMetadata);
    priceDataBatch.push(...priceData);
  } catch (err) {
    console.error("Unexpected error in getPoolTokenPriceMultiple:", err);
    // readd the failed batch so it can be retried in the next iteration
    swapsBatch.push(..._swapsBatch);
  }

  // Save token metadata and price data to the database if we reached the batch size
  if (priceDataBatch.length < FETCH_HELIUS_WRITE_GQL_BATCH_SIZE) return;
  const _tokensDataBatch = tokensDataBatch;
  const _priceDataBatch = priceDataBatch;
  // clear batches before all async calls for the same reason as above
  tokensDataBatch = [];
  priceDataBatch = [];

  try {
    const uniqueTokens = Array.from(new Map(_tokensDataBatch.map((token) => [token.mint, token])).values());

    const result = await gql.UpsertManyTokensAndPriceHistoryMutation({
      tokens: uniqueTokens.map((token) => ({
        mint: token.mint,
        name: token.metadata.name,
        symbol: token.metadata.symbol,
        description: token.metadata.description,
        uri: token.metadata.imageUri,
        mint_burnt: token.mintBurnt,
        freeze_burnt: token.freezeBurnt,
        supply: token.supply?.toString(),
        decimals: token.decimals,
        is_pump_token: token.isPumpToken,
      })),
      priceHistory: _priceDataBatch.map(({ mint, price, timestamp, swap }) => ({
        mint,
        price: price.toString(),
        amount_in: "amountIn" in swap ? swap.amountIn.toString() : undefined,
        min_amount_out: "minimumAmountOut" in swap ? swap.minimumAmountOut.toString() : undefined,
        max_amount_in: "maxAmountIn" in swap ? swap.maxAmountIn.toString() : undefined,
        amount_out: "amountOut" in swap ? swap.amountOut.toString() : undefined,
        created_at: new Date(timestamp),
      })),
    });

    if (result.error) {
      console.error("Unexpected error in UpsertManyTokensAndPriceHistoryMutation:", result.error);
      priceDataBatch.push(..._priceDataBatch);
    } else {
      console.log(`Upserted ${uniqueTokens.length} tokens`);
      console.log(`Saved ${_priceDataBatch.length} price data points`);
    }
  } catch (err) {
    console.error("Unexpected error in handleSwapData:", err);
    priceDataBatch.push(..._priceDataBatch);
  }
};

/* -------------------------------- WEBSOCKET ------------------------------- */
// 1. Start the websocket subscription
// 2. Restart the whole process on global error
// 3. Restart the websocket connection on close
// 4. Terminate the connection (which will trigger a reconnect) if:
//   a. No pong received within 30s (we ping every 10s)
//   b. No messages received within 5s
const setup = async (ws: WebSocket, gql: GqlClient["db"], connectionId: string) => {
  return new Promise((_, reject) => {
    let lastMessageTime = Date.now();
    let lastPongTime = Date.now();
    let pingTimeout: NodeJS.Timeout;
    let heartbeatInterval: NodeJS.Timeout;
    let pingInterval: NodeJS.Timeout;

    // Terminate connection if no pong received within 30s
    const heartbeat = () => {
      clearTimeout(pingTimeout);
      pingTimeout = setTimeout(() => {
        const timeSinceLastPong = Date.now() - lastPongTime;
        console.log(
          `[${connectionId}] Ping timeout - terminating connection. Time since last pong: ${timeSinceLastPong}ms`,
        );
        ws.close(CLOSE_CODES.PING_TIMEOUT, "Ping timeout");
      }, 30_000);
    };

    ws.on("pong", () => {
      lastPongTime = Date.now();
      const timeSinceLastMessage = Date.now() - lastMessageTime;
      console.log(`[${connectionId}] Pong received. Time since last message: ${timeSinceLastMessage}ms`);
      heartbeat();
    });

    ws.onopen = () => {
      console.log(`[${connectionId}] WebSocket connection opened at ${new Date().toISOString()}`);
      heartbeat();

      // Start heartbeat check every 10 seconds
      heartbeatInterval = setInterval(() => {
        const timeSinceLastMessage = Date.now() - lastMessageTime;
        if (timeSinceLastMessage > 5_000) {
          console.log(
            `[${connectionId}] No data received for 5 seconds - reconnecting. Last message was at ${new Date(lastMessageTime).toISOString()}`,
          );
          ws.close(CLOSE_CODES.NO_DATA, "No data received");
        }
      }, 10_000);

      ws.send(
        JSON.stringify({
          jsonrpc: "2.0",
          id: 420,
          method: "transactionSubscribe",
          params: [
            { failed: false, accountInclude: [RaydiumAmmParser.PROGRAM_ID.toString()] },
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
      lastMessageTime = Date.now();

      const obj = JSON.parse(event.data.toString());
      const result = obj.params?.result as TransactionSubscriptionResult | undefined;

      if (result) {
        const swapAccounts = handleLogs(result);
        handleSwapData(gql, swapAccounts);
      } else {
        // Log other types of messages (like subscription confirmations)
        console.log(`Received non-swap message: ${JSON.stringify(obj).slice(0, 200)}...`);
      }
    };

    ws.onclose = (event) => {
      console.log(`[${connectionId}] WebSocket connection closing. Code: ${event.code}, Reason: ${event.reason}`);
      // Clean up all intervals and timeouts
      clearInterval(heartbeatInterval);
      clearInterval(pingInterval);
      clearTimeout(pingTimeout);

      reject(
        new Error(
          `[${connectionId}] WebSocket connection closed at ${new Date().toISOString()}. Code: ${event.code}, Reason: ${event.reason}`,
        ),
      );
    };

    ws.onerror = (error) => {
      console.log(`[${connectionId}] WebSocket error at ${new Date().toISOString()}:`, error);
      ws.close(CLOSE_CODES.MANUAL_RESTART, "Error occurred");
    };

    // Send ping every 10s
    pingInterval = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
        console.log(
          `[${connectionId}] Ping sent at ${new Date().toISOString()}. Time since last message: ${Date.now() - lastMessageTime}ms`,
        );
      } else {
        console.log(`[${connectionId}] Cannot send ping - WebSocket state: ${ws.readyState}. Forcing restart...`);
        ws.close(CLOSE_CODES.MANUAL_RESTART, "Invalid websocket state");
      }
    }, 10_000);
  });
};

let currentConnectionId = 0;
export const start = async () => {
  while (true) {
    const connectionId = `conn_${++currentConnectionId}`;
    let ws: WebSocket | null = null;

    try {
      console.log(`[${connectionId}] Starting new WebSocket connection`);
      ws = new WebSocket(`wss://atlas-mainnet.helius-rpc.com/?api-key=${env.HELIUS_API_KEY}`);

      const gql = (
        await createGqlClient({
          url: env.NODE_ENV !== "production" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
          hasuraAdminSecret: env.NODE_ENV !== "production" ? "password" : env.HASURA_ADMIN_SECRET,
        })
      ).db;

      await setup(ws, gql, connectionId);
    } catch (err) {
      console.warn(`[${connectionId}] Error in indexer, restarting in a second...`);
      console.error(err);

      // Ensure WebSocket is properly closed
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.close(CLOSE_CODES.MANUAL_RESTART, "Error occurred");
      }

      await new Promise((resolve) => setTimeout(resolve, 1_000));
    }
  }
};
