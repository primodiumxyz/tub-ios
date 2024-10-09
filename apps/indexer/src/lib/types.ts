import { PublicKey } from "@solana/web3.js";

import { PLATFORMS } from "@/lib/constants";

export type PriceData = {
  mint: string;
  price: number;
  platform: (typeof PLATFORMS)[number];
};

export type SwapAccounts = {
  tokenX: PublicKey;
  tokenY: PublicKey;
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
