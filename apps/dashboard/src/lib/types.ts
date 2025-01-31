/* --------------------------------- TOKENS --------------------------------- */
/**
 * A token with its metadata and trading stats
 *
 * @property mint - The mint address of the token
 * @property name - The name of the token
 * @property symbol - The symbol of the token
 * @property imageUri (optional) - The URI of the token's image
 * @property volumeUsd - The volume of the token in USD during the last 30 minutes
 * @property priceChangePct - The price change percentage of the token during the last 30 minutes
 * @property tradeCount - The number of trades of the token during the last 30 minutes
 * @property latestPriceUsd - The latest price of the token in USD
 * @property supply - The supply of the token
 */
export type Token = {
  mint: string;
  name: string;
  symbol: string;
  imageUri?: string;
  volumeUsd: number;
  priceChangePct: number;
  tradeCount: number;
  latestPriceUsd: number;
  supply: number;
};

/**
 * A price point for a token (when a trade happened)
 *
 * @property timestamp - The timestamp of the trade
 * @property price - The new price of the token in USD after the trade
 */
export type TokenPrice = {
  timestamp: number;
  price: number;
};

/* --------------------------------- TRADES --------------------------------- */
/**
 * A trade for a token
 *
 * @property id - The ID of the database row
 * @property timestamp - The timestamp of the trade
 * @property userWallet - The wallet address of the user who made the trade
 * @property token - The mint address of the token
 * @property price - The new price of the token after the trade
 * @property amount - The amount of the token traded
 * @property value - The value of the trade in USD
 * @property type - The type of the trade (buy or sell)
 * @property success - Whether the trade was successful
 * @property error - The error that occurred during the trade (if any)
 */
export type Trade = {
  id: string;
  timestamp: number;
  userWallet: string;
  token: string;
  price: number;
  amount: number;
  value: number;
  type: "buy" | "sell";
  success: boolean;
  error: string | null;
};

/**
 * A group of trades for a token (buy + sell attempts)
 *
 * @property id - The ID of the database row
 * @property token - The mint address of the token
 * @property userWallet - The wallet address of the user who made the trades
 * @property timestamp - The timestamp of the most recent trade
 * @property trades - The list of trades
 * @property netProfit - The net profit
 * @property status - The status of the group (open, filled, error)
 * @property error - The error that occurred during the trades (if any)
 */
export type GroupedTrade = {
  id: string; // Using buy trade's id
  token: string;
  userWallet: string;
  timestamp: number; // Most recent trade's timestamp
  trades: Trade[];
  netProfit: number;
  status: "open" | "filled" | "error";
  error: string | null;
};

/**
 * Filters for the trade analytics
 *
 * @property userWalletOrTokenMint - The wallet address or token mint to filter by
 * @property limit - The maximum number of trades to return
 */
export type TradeFilters = {
  userWalletOrTokenMint?: string;
  limit?: number;
};

/* ---------------------------------- STATS --------------------------------- */
/**
 * Stats for the trade analytics (either global, or by token, or by user wallet, or both)
 *
 * @property pnlUsd - The net profit in USD
 * @property volumeUsd - The volume in USD
 * @property tradeCount - The number of trades
 * @property successRate - The success rate of the trades
 */
export type Stats = {
  pnlUsd: number;
  volumeUsd: number;
  tradeCount: number;
  successRate: number;
};

/**
 * Filters for the stats (either global, or by token, or by user wallet, or both)
 *
 * @property userWallet - The wallet address to filter by
 * @property tokenMint - The token mint to filter by
 */
export type StatsFilters = {
  userWallet?: string;
  tokenMint?: string;
};
