import { INTERVALS } from "@/lib/constants";

export type Interval = (typeof INTERVALS)[number];

export type Token = {
  mint?: string;
  imageUri?: string;
  name?: string;
  symbol?: string;
  latestPrice: number;
  liquidity?: string;
  marketCap?: string;
  volume?: string;
};

export type TokenPrice = {
  timestamp: number;
  price: number;
};

export type TokenCandle = {
  o: number;
  h: number;
  l: number;
  c: number;
  v: number | null;
  t: number;
};

export type TokenCandles = {
  o: (number | null)[];
  h: (number | null)[];
  l: (number | null)[];
  c: (number | null)[];
  v: (number | null)[];
  t: (number | null)[];
};
