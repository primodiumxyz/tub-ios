import { PublicKey } from "@solana/web3.js";

import { PLATFORMS } from "@/lib/constants";
import { MinimalParser } from "@/lib/parsers/minimal-parser";

export type Program = {
  id: string;
  publicKey: PublicKey;
  parser: MinimalParser | Omit<MinimalParser, "programId" | "swapInstructions" | "getSwapInstructionNames">;
  swaps?: {
    name: string;
    accounts: string[][];
  }[];
};
export type SwapInstructionDetails = {
  name: string;
  discriminator: number;
  accountIndexes: [number, number];
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
