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

export type TokenPrice = {
  timestamp: number;
  price: number;
};

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

export type TradeFilters = {
  userWalletOrTokenMint?: string;
  limit?: number;
};

export type Stats = {
  pnlUsd: number;
  volumeUsd: number;
  tradeCount: number;
  successRate: number;
};

export type StatsFilters = {
  userWallet?: string;
  tokenMint?: string;
};
