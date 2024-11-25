import { PublicKey } from "@solana/web3.js";

import { SwapBaseInArgs, SwapBaseOutArgs } from "@/lib/parsers/raydium-amm-parser";

/* ------------------------------- PARSED DATA ------------------------------ */
export enum SwapType {
  IN = "in",
  OUT = "out",
}

export type Swap<T extends SwapType> = {
  vaultA: PublicKey;
  vaultB: PublicKey;
  type: T;
  args: T extends SwapType.IN ? SwapBaseInArgs : SwapBaseOutArgs;
  timestamp: number;
};

export type SwapWithPriceData<T extends SwapType = SwapType> = Swap<T> & {
  mint: PublicKey;
  priceUsd: number;
};

/* ----------------------------------- RPC ---------------------------------- */
export type ParsedTokenBalanceInfo = {
  isNative: boolean;
  mint: string;
  owner: string;
  state: string;
  tokenAmount: {
    amount: string;
    decimals: number;
    uiAmount?: number;
    uiAmountString?: string;
  };
};
