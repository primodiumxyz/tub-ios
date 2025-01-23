import {
  Connection,
  Keypair,
  PublicKey,
  SystemProgram,
  TransactionInstruction,
  TransactionMessage,
} from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";
import { TransactionService } from "./TransactionService";
import { TransactionType } from "../types";

export interface TransferRequest {
  fromAddress: string;
  toAddress: string;
  amount: bigint;
  tokenId?: string;
  nativeSol?: boolean;
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
    if (request.nativeSol) {
      transferInstruction = SystemProgram.transfer({
        fromPubkey: new PublicKey(request.fromAddress),
        toPubkey: new PublicKey(request.toAddress),
        lamports: request.amount,
      });
    } else if (!request.nativeSol && request.tokenId) {
      const tokenMint = new PublicKey(request.tokenId);
      const fromPublicKey = new PublicKey(request.fromAddress);
      const toPublicKey = new PublicKey(request.toAddress);

      const fromTokenAccount = getAssociatedTokenAddressSync(tokenMint, fromPublicKey);
      const toTokenAccount = getAssociatedTokenAddressSync(tokenMint, toPublicKey);

      transferInstruction = createTransferInstruction(fromTokenAccount, toTokenAccount, fromPublicKey, request.amount);
    } else {
      throw new Error("Invalid transfer request");
    }

    const { blockhash, lastValidBlockHeight } = await this.connection.getLatestBlockhash();

    const message = new TransactionMessage({
      payerKey: this.feePayerKeypair.publicKey,
      recentBlockhash: blockhash,
      instructions: [transferInstruction],
    }).compileToV0Message([]);

    const base64Message = this.transactionService.registerTransaction(
      message,
      lastValidBlockHeight,
      TransactionType.TRANSFER,
      false,
      0,
      1,
    );

    return {
      transactionMessageBase64: base64Message,
    };
  }
}
