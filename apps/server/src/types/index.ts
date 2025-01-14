import { PublicKey } from "@solana/web3.js";
import { Subject, Subscription } from "rxjs";

export enum SwapType {
  BUY = 1, // When buying any token with USDC
  SELL_PARTIAL = 2, // When selling part of token balance for USDC
  SELL_ALL = 3, // When selling entire token balance for USDC
  TRANSFER = 4, // When transferring tokens to another user
}

export type ResponseType = "success" | "fail" | "rebuild";

// Base swap request types
export type UserPrebuildSwapRequest = {
  buyTokenId: string;
  sellTokenId: string;
  sellQuantity: number;
  slippageBps?: number;
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

export type SubmitSignedTransactionResponse = {
  responseType: ResponseType;
  txid?: string;
  timestamp?: number | null;
  rebuild?: PrebuildSwapResponse;
  error?: string;
};

export interface SwapSubscription {
  /** Subject that emits new swap transactions */
  subject: Subject<PrebuildSwapResponse>;
  /** RxJS subscription for cleanup */
  subscription: Subscription;
  /** Current active swap request */
  request: ActiveSwapRequest;
}

// Transfer types
export interface TransferRequest {
  fromAddress: string;
  toAddress: string;
  amount: bigint;
  tokenId: string;
}

export interface SignedTransfer {
  transactionBase64: string;
  signatureBase64: string;
  signerBase58: string;
}

// Codex types
export interface CodexTokenResponse {
  token: string;
  expiry: string;
}

// Analytics types
export interface ClientEvent {
  userAgent: string;
  userWallet: string;
  source?: string;
  errorDetails?: string;
  buildVersion?: string;
}

export type TokenPurchaseOrSaleEvent = ClientEvent & {
  tokenMint: string;
  tokenAmount: string;
  tokenPriceUsd: string;
};

export type LoadingTimeEvent = ClientEvent & {
  identifier: string;
  timeElapsedMs: number;
  attemptNumber: number;
  totalTimeMs: number;
  averageTimeMs: number;
};

export type AppDwellTimeEvent = ClientEvent & {
  dwellTimeMs: number;
};

export type TokenDwellTimeEvent = ClientEvent & {
  tokenMint: string;
  dwellTimeMs: number;
};
