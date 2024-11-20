import { createTransferInstruction } from "@solana/spl-token";
import { PublicKey, Transaction } from "@solana/web3.js";
import { PrebuildSwapResponse } from "../types/PrebuildSwapRequest";
import { OctaneService } from "./OctaneService";
import { SwapRequest } from "./TubService";

export const buildTx = async (args: SwapRequest & {
  octane: OctaneService;
  feeAmount: number;
}) => {
  let transaction: Transaction | null = null;
  if (args.feeAmount === 0) {
    const swapInstructions = await args.octane.getQuoteAndSwapInstructions(
      {
        inputMint: args.sellTokenId,
        outputMint: args.buyTokenId,
        amount: args.sellQuantity,
        autoSlippage: true,
        minimizeSlippage: true,
        onlyDirectRoutes: false,
        asLegacyTransaction: false,
      },
      args.userPublicKey,
    );
    transaction = await args.octane.buildCompleteSwap(swapInstructions, null);
  } else {
    const feeOptions = {
      sourceAccount: args.sellTokenAccount,
      destinationAccount: args.octane.getSettings().tradeFeeRecipient,
      amount: Number((BigInt(args.feeAmount) * BigInt(args.sellQuantity!)) / 100n), // divide by 100 because feeAmount is in basis points
    };

    const feeTransferInstruction = createTransferInstruction(
      feeOptions.sourceAccount,
      feeOptions.destinationAccount,
      args.userPublicKey,
      feeOptions.amount,
    );

    const swapInstructions = await args.octane.getQuoteAndSwapInstructions(
      {
        inputMint: args.sellTokenId,
        outputMint: args.buyTokenId,
        amount: args.sellQuantity - feeOptions.amount,
        autoSlippage: true,
        minimizeSlippage: true,
        onlyDirectRoutes: false,
        asLegacyTransaction: false,
      },
      args.userPublicKey,
    );
    transaction = await args.octane.buildCompleteSwap(swapInstructions, feeTransferInstruction);
  }

  const response: PrebuildSwapResponse = {
    transactionBase64: Buffer.from(transaction.serialize()).toString("base64"),
    ...args,
    hasFee: args.feeAmount > 0,
    timestamp: Date.now(),
  };

  return { ...response, transaction };
};
