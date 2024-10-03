import { PublicKey } from "@solana/web3.js";

export type PriceData = {
  mint: string;
  price: number;
};

export type SwapAccounts = {
  poolCoin: PublicKey;
  poolPc: PublicKey;
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
