import { Connection, Keypair, PublicKey, TransactionMessage } from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";
import { TransactionService } from "./TransactionService";
import { SwapType } from "../types";

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
    const tokenMint = new PublicKey(request.tokenId);
    const fromPublicKey = new PublicKey(request.fromAddress);
    const toPublicKey = new PublicKey(request.toAddress);

    const fromTokenAccount = getAssociatedTokenAddressSync(tokenMint, fromPublicKey);
    const toTokenAccount = getAssociatedTokenAddressSync(tokenMint, toPublicKey);

    const transferInstruction = createTransferInstruction(
      fromTokenAccount,
      toTokenAccount,
      fromPublicKey,
      request.amount,
    );

    const { blockhash } = await this.connection.getLatestBlockhash();

    const message = new TransactionMessage({
      payerKey: this.feePayerKeypair.publicKey,
      recentBlockhash: blockhash,
      instructions: [transferInstruction],
    }).compileToV0Message([]);

    const base64Message = this.transactionService.registerTransaction(message, SwapType.TRANSFER, false, 0, 1);

    return {
      transactionMessageBase64: base64Message,
    };
  }
}
