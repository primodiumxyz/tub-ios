import { PublicKey } from "@solana/web3.js";

export type UserPrebuildSwapRequest = {
  userId: string;
  buyTokenId?: string;
  sellTokenId?: string;
  sellQuantity?: number;
};