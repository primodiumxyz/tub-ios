import { GqlClient } from "../../src/index";
import { createClientNoCache, toPgComposite } from "../lib/common";
import { DEFAULT_TRADES_AMOUNT, DEFAULT_START_DATE } from "./config";

/* -------------------------------------------------------------------------- */
/*                                    UTILS                                   */
/* -------------------------------------------------------------------------- */

interface InsertMockTradeHistoryOptions {
  count: number;
  from: Date;
  batchSize?: number;
  onProgress?: (inserted: number, total: number) => void;
}

export const insertMockTradeHistory = async (gql: GqlClient, options: InsertMockTradeHistoryOptions): Promise<void> => {
  const { count, from, batchSize = 1000, onProgress } = options;
  const tokenMintCount = Math.ceil(count * 0.05);
  const tokens = Array.from({ length: tokenMintCount }, (_, i) => ({
    mint: getRandomMint(),
    name: `Token ${getLetterIndex(i)}`.slice(0, 255),
    symbol: `T${getLetterIndex(i)}`.slice(0, 10),
    description: `Description ${getLetterIndex(i)}`.slice(0, 255),
    imageUri: `https://example.com/image.png`,
    externalUrl: `https://example.com`,
    supply: 99999999999999,
    decimals: "6",
    isPumpToken: true,
  }));

  const batches = Math.ceil(count / batchSize);
  let inserted = 0;

  for (let i = 0; i < batches; i++) {
    const batchCount = Math.min(batchSize, count - i * batchSize);
    const res = await gql.db.InsertTradeHistoryManyMutation({
      trades: Array.from({ length: batchCount }, () => {
        const token = tokens[Math.floor(Math.random() * tokens.length)];

        return {
          token_mint: token.mint,
          volume_usd: getRandomVolume().toString(),
          token_price_usd: getRandomPrice().toString(),
          created_at: getRandomDate(from),
          token_metadata: toPgComposite({
            name: token.name,
            symbol: token.symbol,
            description: token.description,
            image_uri: token.imageUri,
            external_url: token.externalUrl,
            decimals: token.decimals,
            supply: token.supply,
            is_pump_token: token.isPumpToken,
          }),
        };
      }),
    });

    if (res.error) throw new Error(res.error.message);
    const affectedRows = res.data?.insert_api_trade_history?.affected_rows;

    if (!affectedRows) throw new Error("Failed to insert mock trade history");

    inserted += affectedRows;
    onProgress?.(inserted, count);
  }
};

const getRandomMint = () => {
  const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
  return Array.from({ length: 44 }, () => ALPHABET[Math.floor(Math.random() * ALPHABET.length)]).join("");
};

// between 0.000000000001 and 10 (18 decimal places)
const getRandomPrice = () => Number((Math.random() * 10 + 0.000000000001).toFixed(18));

// Returns a random number between 0.001 and 10,000 (18 decimal places)
const getRandomVolume = () => Number((Math.random() * 10000 + 0.001).toFixed(18));

// Returns a random date between from and now
const getRandomDate = (from: Date) =>
  new Date(from.getTime() + Math.random() * (new Date().getTime() - from.getTime()));

// Convert an index to an Excel-style column name (A, B, C, ..., Z, AA, AB, ..., ZZ, AAA, ...)
const getLetterIndex = (index: number): string => {
  let columnName = "";
  let num = index;

  while (num >= 0) {
    columnName = String.fromCharCode(65 + (num % 26)) + columnName;
    num = Math.floor(num / 26) - 1;
  }

  return columnName;
};

/* -------------------------------------------------------------------------- */
/*                                   PREPARE                                  */
/* -------------------------------------------------------------------------- */

const prepare = async () => {
  const client = await createClientNoCache();

  await insertMockTradeHistory(client, {
    count: DEFAULT_TRADES_AMOUNT,
    from: DEFAULT_START_DATE,
    onProgress: (inserted, total) => {
      console.log(`Inserting mock data: ${((inserted / total) * 100).toFixed(2)}%`);
    },
  });
};

prepare()
  .then(() => {
    console.log("Mock data inserted");
    process.exit(0);
  })
  .catch((e) => {
    console.error("Error inserting mock data", e);
    process.exit(1);
  });
