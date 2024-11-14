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
