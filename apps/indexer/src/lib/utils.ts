// #!/usr/bin/env node
import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { Connection, ParsedAccountData, PublicKey } from "@solana/web3.js";
import { config } from "dotenv";

import { GqlClient } from "@tub/gql";
import { parseEnv } from "@bin/parseEnv";
import { WRAPPED_SOL_MINT } from "@/lib/constants";
import { RaydiumAmmParser, SwapBaseInArgs, SwapBaseOutArgs } from "@/lib/parsers/raydium-amm-parser";
import { ParsedTokenBalanceInfo, Swap, SwapType, SwapWithPriceData } from "@/lib/types";

config({ path: "../../.env" });

const env = parseEnv();

/* --------------------------------- DECODER -------------------------------- */
export const decodeSwapInfo = <T extends SwapType = SwapType>(
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
  timestamp: number,
): Swap<T>[] => {
  // Filter out the instructions that are not related to a Raydium swap
  const programIxs = parsedIxs.filter(
    (ix) =>
      ix.programId.toString() === RaydiumAmmParser.PROGRAM_ID.toString() &&
      (ix.name === "swapBaseIn" || ix.name === "swapBaseOut"),
  );
  if (programIxs.length === 0) return [];

  // For each instruction
  return programIxs
    .map((ix) => {
      const vaultA = ix.accounts.find((account) => account.name === "poolCoinTokenAccount")?.pubkey;
      const vaultB = ix.accounts.find((account) => account.name === "poolPcTokenAccount")?.pubkey;
      if (!vaultA || !vaultB) return;

      return {
        vaultA,
        vaultB,
        type: (ix.name === "swapBaseIn" ? SwapType.IN : SwapType.OUT) as T,
        args: ix.args as T extends SwapType.IN ? SwapBaseInArgs : SwapBaseOutArgs,
        timestamp,
      };
    })
    .filter((swap) => swap !== undefined);
};

/* ------------------------------ PROCESS DATA ------------------------------ */
export const fetchPriceData = async <T extends SwapType = SwapType>(
  connection: Connection,
  swaps: Swap<T>[],
): Promise<SwapWithPriceData<T>[]> => {
  // Break swaps into batches of 50 (max 100 accounts passed to `getMultipleParsedAccounts`)
  const batchSize = 50;
  const batches = [];
  for (let i = 0; i < swaps.length; i += batchSize) {
    batches.push(swaps.slice(i, i + batchSize));
  }

  // Process each batch in parallel
  const batchResults = await Promise.all(
    batches.map(async (batchSwaps) => {
      // 1. Get parsed accounts for all vaults in this batch
      const parsedAccounts = await connection.getMultipleParsedAccounts(
        batchSwaps.map((swap) => [swap.vaultA, swap.vaultB]).flat(),
        {
          commitment: "confirmed",
        },
      );

      // 2. Get account info for each token traded in each swap
      return batchSwaps.map((swap, i) => ({
        ...swap,
        mintA: (parsedAccounts.value[i * 2]?.data as ParsedAccountData | undefined)?.parsed.info as
          | ParsedTokenBalanceInfo
          | undefined,
        mintB: (parsedAccounts.value[i * 2 + 1]?.data as ParsedAccountData | undefined)?.parsed.info as
          | ParsedTokenBalanceInfo
          | undefined,
      }));
    }),
  );

  // Flatten batch results
  const swapsWithAccountInfo = batchResults.flat();

  // 3. Get the price for each token traded in each swap (except for WSOL)
  const uniqueMints = new Set(
    swapsWithAccountInfo
      .flatMap((swap) => [swap.mintA?.mint, swap.mintB?.mint])
      .filter((mint): mint is string => !!mint && mint !== WRAPPED_SOL_MINT.toString()),
  );

  // 4. Fetch prices from Jupiter API
  const priceResponse = await fetchWithRetry(
    `${env.JUPITER_API_ENDPOINT}/price?ids=${Array.from(uniqueMints).join(",")}`,
    {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    },
  );

  const priceData = (await priceResponse.json()) as {
    data: {
      [id: string]: { price: number };
    };
  };

  // 5. Create price lookup map
  const priceMap = new Map(Object.entries(priceData.data).map(([id, { price }]) => [id, price]));

  // 6. Map swaps to include price data
  return swapsWithAccountInfo
    .map((swap) => {
      const tokenMint =
        swap.mintA?.mint === WRAPPED_SOL_MINT.toString()
          ? swap.mintB?.mint
          : swap.mintB?.mint === WRAPPED_SOL_MINT.toString()
            ? swap.mintA?.mint
            : undefined;
      if (!tokenMint) return;

      const price = priceMap.get(tokenMint);
      if (price === undefined) return;

      return {
        vaultA: swap.vaultA,
        vaultB: swap.vaultB,
        type: swap.type,
        args: swap.args,
        timestamp: swap.timestamp,
        mint: new PublicKey(tokenMint),
        priceUsd: price,
      };
    })
    .filter((swap): swap is SwapWithPriceData<T> => swap !== undefined);
};

/* -------------------------------- DATABASE -------------------------------- */
export const upsertTrades = async (gql: GqlClient["db"], trades: SwapWithPriceData[]) => {
  return await gql.UpsertTradesMutation({
    trades: trades.map((trade) => {
      const amount =
        trade.type === SwapType.IN
          ? (trade as SwapWithPriceData<SwapType.IN>).args.amountIn
          : (trade as SwapWithPriceData<SwapType.OUT>).args.amountOut;
      const volumeUsd = Number(amount) * trade.priceUsd;

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
