import { PublicKey } from "@solana/web3.js";

import { PLATFORMS } from "@/lib/constants";

export type Program = {
  id: string;
  publicKey: PublicKey;
  parser: any;
  swaps: {
    name: string;
    accounts: string[][];
  }[];
  minimal?: boolean;
};

export type PriceData = {
  mint: string;
  price: number;
  platform: (typeof PLATFORMS)[number];
};

export type SwapAccounts = {
  vaultA: PublicKey;
  vaultB: PublicKey;
  platform: (typeof PLATFORMS)[number];
};

export type ParsedAccountData = {
  parsed: {
    info: {
      mint?: string;
      tokenAmount?: {
        uiAmount?: number;
      };
    };
  };
};
