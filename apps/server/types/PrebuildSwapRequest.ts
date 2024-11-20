import { PublicKey } from "@solana/web3.js";

export type UserPrebuildSwapRequest = {
  buyTokenId: string;
  sellTokenId: string;
  sellQuantity: number;
};

export type PrebuildSwapResponse = UserPrebuildSwapRequest & {
  transactionBase64: string;
  hasFee: boolean;
  timestamp: number;
};
