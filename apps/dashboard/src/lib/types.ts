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
