import {
  Connection,
  Keypair,
  PublicKey,
  SystemProgram,
  TransactionInstruction,
  TransactionMessage,
  ComputeBudgetProgram,
} from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";
import { TransactionService } from "./TransactionService";
import { TransactionType } from "../types";

export interface TransferRequest {
  fromAddress: string;
  toAddress: string;
  amount: bigint;
  tokenId: string;
}

export interface SignedTransfer {
  transactionMessageBase64: string;
  signatureBase64: string;
  signerBase58: string;
}

export class TransferService {
  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
    private transactionService: TransactionService,
  ) {}

  async getTransfer(request: TransferRequest): Promise<{ transactionMessageBase64: string }> {
    let transferInstruction: TransactionInstruction;
    if (request.tokenId === "SOLANA") {
      transferInstruction = SystemProgram.transfer({
        fromPubkey: new PublicKey(request.fromAddress),
        toPubkey: new PublicKey(request.toAddress),
        lamports: request.amount,
      });
    } else if (request.tokenId) {
      const tokenMint = new PublicKey(request.tokenId);
      const fromPublicKey = new PublicKey(request.fromAddress);
      const toPublicKey = new PublicKey(request.toAddress);

      const fromTokenAccount = getAssociatedTokenAddressSync(tokenMint, fromPublicKey);
      const toTokenAccount = getAssociatedTokenAddressSync(tokenMint, toPublicKey);

      transferInstruction = createTransferInstruction(fromTokenAccount, toTokenAccount, fromPublicKey, request.amount);
    } else {
      throw new Error("Invalid transfer request");
    }

    const slot = await this.connection.getSlot("finalized");
    const { blockhash, lastValidBlockHeight } = await this.connection.getLatestBlockhash("finalized");

    let computeUnitLimitInstruction: TransactionInstruction | undefined;
    let computeUnitPriceInstruction: TransactionInstruction | undefined;
    if (request.tokenId !== "SOLANA") {
      // make a compute unit limit instruction
      computeUnitLimitInstruction = ComputeBudgetProgram.setComputeUnitLimit({
        units: 5000,
      });
      // make a compute unit price instruction
      computeUnitPriceInstruction = ComputeBudgetProgram.setComputeUnitPrice({
        microLamports: 100000,
      });
    }

    const allInstructions = [computeUnitLimitInstruction, computeUnitPriceInstruction, transferInstruction].filter(
      (instruction) => instruction !== undefined,
    );

    const message = new TransactionMessage({
      payerKey: this.feePayerKeypair.publicKey,
      recentBlockhash: blockhash,
      instructions: allInstructions,
    }).compileToV0Message([]);

    const base64Message = this.transactionService.registerTransaction(
      message,
      lastValidBlockHeight,
      TransactionType.TRANSFER,
      false,
      slot,
      1,
    );

    return {
      transactionMessageBase64: base64Message,
    };
  }
}
