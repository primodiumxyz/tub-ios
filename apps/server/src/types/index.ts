import { PublicKey } from "@solana/web3.js";
import { Subject, Subscription } from "rxjs";

// Base swap request types
export type UserPrebuildSwapRequest = {
  buyTokenId: string;
  sellTokenId: string;
  sellQuantity: number;
};

export type PrebuildSwapResponse = UserPrebuildSwapRequest & {
  transactionMessageBase64: string;
  hasFee: boolean;
  timestamp: number;
};

export type PrebuildSignedSwapResponse = PrebuildSwapResponse & {
  feePayerSignature: string;
};

// Internal swap types
export type ActiveSwapRequest = UserPrebuildSwapRequest & {
  buyTokenAccount: PublicKey;
  sellTokenAccount: PublicKey;
  userPublicKey: PublicKey;
};

export interface SwapSubscription {
  /** Subject that emits new swap transactions */
  subject: Subject<PrebuildSwapResponse>;
  /** RxJS subscription for cleanup */
  subscription: Subscription;
  /** Current active swap request */
  request: ActiveSwapRequest;
}
