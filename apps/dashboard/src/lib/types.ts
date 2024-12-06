import { INTERVALS } from "@/lib/constants";

export type Interval = (typeof INTERVALS)[number];

export type Token = {
  mint: string;
  name: string;
  symbol: string;
  imageUri?: string;
  volumeUsd: number;
  priceChangePct: number;
  tradeCount: number;
  supply: number;
};

export type TokenPrice = {
  timestamp: number;
  price: number;
};
