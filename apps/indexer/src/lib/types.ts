import { PublicKey, TokenBalance } from "@solana/web3.js";

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

export type TokenMetadata = {
  mint: string;
  metadata: {
    name: string | null;
    symbol: string | null;
    description: string | null;
    imageUri: string | null;
  };
  mintBurnt: boolean | null;
  freezeBurnt: boolean | null;
  supply: number | null;
  decimals: number | null;
  isPumpToken: boolean | null;
};

export type PriceData<T extends SwapType = SwapType> = {
  mint: string;
  price: number;
  timestamp: number;
  swap: T extends SwapType.IN ? SwapBaseInArgs : SwapBaseOutArgs;
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

/* -------------------------------- WEBSOCKET ------------------------------- */
// Data of a non-failed and confirmed token transaction received from the Geyser websocket subscription
export type TransactionSubscriptionResult = {
  transaction: {
    transaction: TransactionData;
    meta: TransactionMetaData;
    version: TransactionVersion;
  };
  signature: string;
  slot: number;
};

export type TransactionData = {
  signatures: Array<string>;
  message: TransactionMessageData;
};

export type TransactionMessageData = {
  accountKeys: Array<StringifiedAccountKey>;
  recentBlockhash: string;
  instructions: Array<TransactionInstructionData>;
  addressTableLookups?: Array<TransactionAddressTableLookupsData>;
};

export type TransactionMetaData = {
  err: null;
  status: {
    Ok: null;
  };
  fee: number;
  preBalances: Array<number>;
  postBalances: Array<number>;
  innerInstructions: Array<TransactionInnerInstructionData>;
  logMessages: Array<string>;
  preTokenBalances: Array<TransactionTokenBalanceData>;
  postTokenBalances: Array<TransactionTokenBalanceData>;
  rewards: null;
  computeUnitsConsumed: number;
};

export type TransactionVersion = 0 | "legacy";

export type TransactionInstructionData = TransactionInstructionParsedData | TransactionInstructionRawData;
export type TransactionInstructionParsedData = {
  program: string;
  programId: string;
  parsed: {
    info: {
      [key: string]: string | number | null;
    };
    type: string;
  };
  stackHeight: number | null;
};
export type TransactionInstructionRawData = {
  programId: string;
  accounts: Array<string>;
  data: string;
  stackHeight: number | null;
};

type TransactionAddressTableLookupsData = {
  accountKey: string;
  writableIndexes: Array<number>;
  readonlyIndexes: Array<number>;
};

type TransactionInnerInstructionData = {
  index: number;
  instructions: Array<TransactionInstructionData>;
};

type TransactionTokenBalanceData = TokenBalance & {
  programId: string;
};

type StringifiedAccountKey = {
  pubkey: string;
  writable: boolean;
  signer: boolean;
  source: "transaction";
};
