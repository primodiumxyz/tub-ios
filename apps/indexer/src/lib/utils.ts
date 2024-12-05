// #!/usr/bin/env node
import { Connection, ParsedAccountData, PublicKey, TransactionInstruction } from "@solana/web3.js";
import { config } from "dotenv";

import { GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { PUMP_FUN_AUTHORITY, WRAPPED_SOL_MINT } from "@/lib/constants";
import { RaydiumAmmParser } from "@/lib/parsers/raydium-amm-parser";
import {
  GetAssetsResponse,
  GetJupiterPriceResponse,
  ParsedTokenBalanceInfo,
  Swap,
  SwapTokenMetadata,
  SwapWithPriceAndMetadata,
  TransactionWithParsed,
} from "@/lib/types";

config({ path: "../../.env" });

const env = parseEnv();

let jupiterAndGetAssetsCallTimes: number[] = [];
let accountsCallTimes: number[] = [];

const calculateAverage = (times: number[]): string => {
  if (times.length === 0) return "0";
  const avg = times.reduce((a, b) => a + b, 0) / times.length;
  return avg.toFixed(3);
};

/* --------------------------------- DECODER -------------------------------- */
export const decodeSwapInfo = (txsWithParsedIxs: TransactionWithParsed[], timestamp: number): Swap[] => {
  // Filter out the instructions that are not related to a Raydium swap
  const programIxs = txsWithParsedIxs.filter(
    (ix) =>
      ix.parsed.programId.toString() === RaydiumAmmParser.PROGRAM_ID.toString() &&
      (ix.parsed.name === "swapBaseIn" || ix.parsed.name === "swapBaseOut"),
  );
  if (programIxs.length === 0) return [];

  // For each instruction
  return programIxs
    .map((ix) => {
      const vaultA = ix.parsed.accounts.find((account) => account.name === "poolCoinTokenAccount")?.pubkey;
      const vaultB = ix.parsed.accounts.find((account) => account.name === "poolPcTokenAccount")?.pubkey;
      if (!vaultA || !vaultB) return;

      // Decode transfer instructions so we can later get the exact amount of tokens traded
      // These instructions are the two immediately after the swap instruction
      const ixIndex = txsWithParsedIxs.indexOf(ix);
      const transferIxs = [txsWithParsedIxs[ixIndex + 1], txsWithParsedIxs[ixIndex + 2]].filter(
        (ix) => ix !== undefined,
      );
      const decodedTransferIxs = RaydiumAmmParser.decodeTransferIxs(...transferIxs.map((ix) => ix.raw));

      const transferInfo = decodedTransferIxs.map((ix) => ({
        accounts: [ix.args.source, ix.args.destination],
        amount: ix.args.amount,
      }));

      return {
        vaultA,
        vaultB,
        transferInfo,
        timestamp,
      };
    })
    .filter((swap) => swap !== undefined);
};

/* ------------------------------ PROCESS DATA ------------------------------ */
export const fetchPriceAndMetadata = async (
  connection: Connection,
  swaps: Swap[],
): Promise<SwapWithPriceAndMetadata[]> => {
  if (swaps.length === 0) return [];

  // Break swaps into batches of 50 (max 100 accounts passed to `getMultipleParsedAccounts`)
  const batchSize = 50;
  const batches = [];
  for (let i = 0; i < swaps.length; i += batchSize) {
    batches.push(swaps.slice(i, i + batchSize));
  }

  // Process each batch in parallel and collect account info
  const swapsWithAccountInfo = (
    await Promise.all(
      batches.map(async (batchSwaps) => {
        // Get parsed accounts for both vaults of each swap
        const beforeAccounts = Date.now();
        const parsedAccounts = await connection.getMultipleParsedAccounts(
          batchSwaps.map((swap) => [swap.vaultA, swap.vaultB]).flat(),
          { commitment: "confirmed" },
        );
        const afterAccounts = Date.now();
        accountsCallTimes.push((afterAccounts - beforeAccounts) / 1000);
        console.log(
          `[${(afterAccounts - beforeAccounts) / 1000}s] 'getMultipleParsedAccounts' (avg: ${calculateAverage(accountsCallTimes)}s)`,
        );

        return batchSwaps.map((swap, i) => {
          // Extract mint info from parsed accounts
          const mintA = (parsedAccounts.value[i * 2]?.data as ParsedAccountData | undefined)?.parsed.info as
            | ParsedTokenBalanceInfo
            | undefined;
          const mintB = (parsedAccounts.value[i * 2 + 1]?.data as ParsedAccountData | undefined)?.parsed.info as
            | ParsedTokenBalanceInfo
            | undefined;

          if (!mintA?.mint || !mintB?.mint) return;

          // Convert mints to strings and check for WSOL
          const mintAStr = mintA.mint.toString();
          const mintBStr = mintB.mint.toString();
          const isWsolA = mintAStr === WRAPPED_SOL_MINT.toString();
          const isWsolB = mintBStr === WRAPPED_SOL_MINT.toString();

          // Skip if neither token is WSOL
          if (!isWsolA && !isWsolB) return;

          // Get the non-WSOL token info
          const tokenMint = isWsolA ? mintBStr : mintAStr;
          const tokenVault = isWsolA ? swap.vaultB : swap.vaultA;

          // Find amount traded by matching token vault and mint in transfer info
          const amountTraded = swap.transferInfo.find((transfer) => {
            return transfer.accounts.includes(tokenVault);
          })?.amount;
          if (!amountTraded) return;

          // Find decimals of the token
          const tokenDecimals = isWsolA ? mintB.tokenAmount.decimals : mintA.tokenAmount.decimals;

          return {
            ...swap,
            mintA: mintAStr,
            mintB: mintBStr,
            tokenMint,
            amount: amountTraded,
            tokenDecimals,
          };
        });
      }),
    )
  )
    .flat()
    .filter((swap): swap is NonNullable<typeof swap> => swap !== undefined);

  // Get unique token mints for price lookup (excluding WSOL)
  const uniqueMints = new Set(swapsWithAccountInfo.map((swap) => swap.tokenMint));

  // Break unique mints into batches of 49
  // TODO: remove when QuickNode Jupiter API is fixed (time here is already long but from 50+ accounts it jumps +4s)
  const mintBatchSize = 49;
  const mintBatches = [];
  const uniqueMintsArray = Array.from(uniqueMints);
  for (let i = 0; i < uniqueMintsArray.length; i += mintBatchSize) {
    mintBatches.push(uniqueMintsArray.slice(i, i + mintBatchSize));
  }

  // Process each mint batch in parallel
  const priceAndMetadataResponses = await Promise.all(
    mintBatches.map(async (mintBatch) => {
      const mintIds = mintBatch.join(",");
      console.log(`Fetching prices for ${mintBatch.length} mints`);

      // Fetch prices from Jupiter API and metadata from QuickNode DAS API
      const before = Date.now();
      const [priceResponse, metadataResponse] = await Promise.all([
        fetchWithRetry(
          `${env.JUPITER_API_ENDPOINT}/price?ids=${mintIds}`,
          {
            method: "GET",
            headers: { "Content-Type": "application/json" },
          },
          1_000,
        ),
        fetchWithRetry(
          `${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`,
          {
            method: "POST",
            body: JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "getAssets",
              params: { ids: Array.from(uniqueMints) },
            }),
            headers: { "Content-Type": "application/json" },
          },
          1_000,
        ),
      ]);
      const after = Date.now();
      jupiterAndGetAssetsCallTimes.push((after - before) / 1000);
      console.log(
        `[${(after - before) / 1000}s] Jupiter '/price' (avg: ${calculateAverage(jupiterAndGetAssetsCallTimes)}s)`,
      );

      return { priceResponse, metadataResponse };
    }),
  );

  // Parse price and metadata responses and create a lookup map
  const priceMap = new Map();
  const metadataMap = new Map();

  for (const { priceResponse, metadataResponse } of priceAndMetadataResponses) {
    const [priceData, metadataData] = (await Promise.all([priceResponse.json(), metadataResponse.json()])) as [
      GetJupiterPriceResponse,
      GetAssetsResponse,
    ];

    for (const [id, { price }] of Object.entries(priceData.data)) {
      priceMap.set(id, price);
    }

    // TODO: remove when QuickNode DAS API is fixed (returns null for a lot of tokens)
    for (const asset of metadataData.result.filter((asset) => asset !== null)) {
      metadataMap.set(asset.id, asset);
    }
  }

  // Map final results with price data
  return swapsWithAccountInfo
    .map((swap) => {
      const price = priceMap.get(swap.tokenMint);
      const metadata = metadataMap.get(swap.tokenMint);
      // TODO: idem (remove when QuickNode DAS API is fixed)
      if (price === undefined /* || metadata === undefined */) return;

      // TODO: idem (remove when QuickNode DAS API is fixed)
      const tokenMetadata = metadata
        ? formatTokenMetadata(metadata)
        : {
            name: "",
            symbol: "",
            description: "",
            isPumpToken: false,
          };

      return {
        vaultA: swap.vaultA,
        vaultB: swap.vaultB,
        timestamp: swap.timestamp,
        mint: new PublicKey(swap.tokenMint),
        priceUsd: price,
        amount: swap.amount,
        tokenDecimals: swap.tokenDecimals,
        metadata: tokenMetadata,
      };
    })
    .filter((swap) => swap !== undefined);
};

const formatTokenMetadata = (data: GetAssetsResponse["result"][number]): SwapTokenMetadata => {
  const metadata = data.content.metadata;
  const files = data.content.files;
  const links = data.content.links;

  return {
    name: metadata.name,
    symbol: metadata.symbol,
    description: metadata.description,
    imageUri: links?.image ?? files.find((file) => file.mime.startsWith("image") && !!file.uri)?.uri,
    externalUrl: links?.external_url,
    supply: data.supply?.print_current_supply,
    isPumpToken: data.authorities.some((authority) => authority.address === PUMP_FUN_AUTHORITY.toString()),
  };
};

/* -------------------------------- DATABASE -------------------------------- */
export const upsertTrades = async (gql: GqlClient["db"], trades: SwapWithPriceAndMetadata[]) => {
  return await gql.UpsertTradesMutation({
    trades: trades.map((trade) => {
      const volumeUsd = (Number(trade.amount) * trade.priceUsd) / 10 ** trade.tokenDecimals;
      const { name, symbol, description, imageUri, externalUrl, supply, isPumpToken } = trade.metadata;

      return {
        token_mint: trade.mint.toString(),
        volume_usd: volumeUsd.toString(),
        token_price_usd: trade.priceUsd.toString(),
        created_at: new Date(trade.timestamp),
        token_metadata: toPgComposite({
          name: name.slice(0, 255),
          symbol: symbol.slice(0, 10),
          description,
          image_uri: imageUri,
          external_url: externalUrl,
          supply: supply, // Don't convert to string here, let toPgComposite handle it
          is_pump_token: isPumpToken,
        }),
      };
    }),
  });
};

/**
 * Converts a JavaScript object to a PostgreSQL composite type string
 * @param obj The object to convert
 * @returns A string in PostgreSQL composite type format: (val1,val2,...)
 * @example
 * toPgComposite({ name: 'Test "Quote"', active: true, count: null })
 * // returns: ("Test ""Quote""",true,NULL)
 */
export const toPgComposite = (obj: Record<string, unknown>): string => {
  const values = Object.values(obj).map((val) => {
    if (val === null || val === undefined) return null;
    // Escape quotes by doubling them (PostgreSQL syntax)
    if (typeof val === "string") return `"${val.replace(/"/g, '""')}"`;
    if (typeof val === "number") return isNaN(val) ? null : val.toString();
    // For any other value that might be numeric (like BigInt) or string
    return val.toString();
  });

  return `(${values.join(",")})`;
};

/* ---------------------------------- UTILS --------------------------------- */
export const fetchWithRetry = async (
  input: RequestInfo | URL,
  init?: RequestInit,
  retry = 5_000,
  timeout = 300_000,
): Promise<Response> => {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(input, {
      ...init,
      signal: controller.signal,
    });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    console.error(`Fetch error: ${String(error)}. Retrying in ${retry / 1000} seconds...`);
    await new Promise((resolve) => setTimeout(resolve, retry));
    return fetchWithRetry(input, init, retry, timeout);
  }
};
