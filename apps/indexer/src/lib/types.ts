import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

import { SwapBaseInArgs, SwapBaseOutArgs } from "@/lib/parsers/raydium-amm-parser";

/* ------------------------------- PARSED DATA ------------------------------ */
export type Swap = {
  vaultA: PublicKey;
  vaultB: PublicKey;
  transferInfo: TransferInformation[];
  timestamp: number;
};

export type SwapWithPriceData = Swap & {
  mint: PublicKey;
  priceUsd: number;
  amount: bigint;
};

export type TransferInformation = {
  accounts: PublicKey[];
  amount: bigint;
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

/* --------------------------------- PARSERS -------------------------------- */
export type TransactionWithParsed = {
  raw: TransactionInstruction;
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsed: ParsedInstruction<Idl, string>;
};
