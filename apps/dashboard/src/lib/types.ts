import { INTERVALS } from "@/lib/constants";

export type Interval = (typeof INTERVALS)[number];

export type Token = {
  mint: string;
  imageUri: string | null;
  name: string;
  symbol: string;
  latestPrice: number;
  liquidity: string;
  marketCap: string | null;
  volume: string;
  pairId: string;
  priceChange: {
    [key in Interval]: number;
  };
  transactions: {
    [key in Interval]: number;
  };
  uniqueBuys: {
    [key in Interval]: number;
  };
  uniqueSells: {
    [key in Interval]: number;
  };
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
