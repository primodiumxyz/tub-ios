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
