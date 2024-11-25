// #!/usr/bin/env node
import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { Connection, ParsedAccountData, PublicKey, TransactionInstruction } from "@solana/web3.js";
import { config } from "dotenv";

import { GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { WRAPPED_SOL_MINT } from "@/lib/constants";
import { RaydiumAmmParser, SwapBaseInArgs, SwapBaseOutArgs } from "@/lib/parsers/raydium-amm-parser";
import { ParsedTokenBalanceInfo, Swap, SwapWithPriceData, TransactionWithParsed } from "@/lib/types";

config({ path: "../../.env" });

const env = parseEnv();

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
export const fetchPriceData = async (connection: Connection, swaps: Swap[]): Promise<SwapWithPriceData[]> => {
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
        const parsedAccounts = await connection.getMultipleParsedAccounts(
          batchSwaps.map((swap) => [swap.vaultA, swap.vaultB]).flat(),
          { commitment: "confirmed" },
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

          return {
            ...swap,
            mintA: mintAStr,
            mintB: mintBStr,
            tokenMint,
            amount: amountTraded,
          };
        });
      }),
    )
  )
    .flat()
    .filter((swap): swap is NonNullable<typeof swap> => swap !== undefined);

  // Get unique token mints for price lookup (excluding WSOL)
  const uniqueMints = new Set(swapsWithAccountInfo.map((swap) => swap.tokenMint));

  // Fetch prices from Jupiter API
  const priceResponse = await fetchWithRetry(
    `${env.JUPITER_API_ENDPOINT}/price?ids=${Array.from(uniqueMints).join(",")}`,
    {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    },
  );

  // Parse price data and create lookup map
  const priceData = (await priceResponse.json()) as { data: { [id: string]: { price: number } } };
  const priceMap = new Map(Object.entries(priceData.data).map(([id, { price }]) => [id, price]));

  // Map final results with price data
  return swapsWithAccountInfo
    .map((swap) => {
      const price = priceMap.get(swap.tokenMint);
      if (price === undefined) return;

      return {
        vaultA: swap.vaultA,
        vaultB: swap.vaultB,
        timestamp: swap.timestamp,
        mint: new PublicKey(swap.tokenMint),
        priceUsd: price,
        amount: swap.amount,
      };
    })
    .filter((swap): swap is SwapWithPriceData => swap !== undefined);
};

/* -------------------------------- DATABASE -------------------------------- */
export const upsertTrades = async (gql: GqlClient["db"], trades: SwapWithPriceData[]) => {
  return await gql.UpsertTradesMutation({
    trades: trades.map((trade) => {
      const volumeUsd = Number(trade.amount) * trade.priceUsd;

      return {
        token_mint: trade.mint.toString(),
        volume_usd: volumeUsd.toString(),
        token_price_usd: trade.priceUsd.toString(),
        created_at: new Date(trade.timestamp),
      };
    }),
  });
};

/* ---------------------------------- UTILS --------------------------------- */
export const fetchWithRetry = async (
  input: RequestInfo | URL,
  init?: RequestInit,
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
    console.error(`Fetch error: ${String(error)}. Retrying in 5 seconds...`);
    await new Promise((resolve) => setTimeout(resolve, 5000));
    return fetchWithRetry(input, init);
  }
};
