import { Connection, Keypair, PublicKey, Transaction } from "@solana/web3.js";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";

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

export class TransferService {
  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
  ) {}

  async getSignedTransfer(request: TransferRequest): Promise<SignedTransfer> {
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

    const transaction = new Transaction();
    transaction.feePayer = this.feePayerKeypair.publicKey;
    transaction.add(transferInstruction);

    const blockhash = await this.connection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash.blockhash;

    transaction.sign(this.feePayerKeypair);

    const sigData = transaction.signatures[0];
    if (!sigData) {
      throw new Error("Transaction is not signed by feePayer");
    }
    const { signature: rawSignature, publicKey } = sigData;

    if (!rawSignature) {
      throw new Error("Transaction is not signed by feePayer");
    }

    return {
      transactionBase64: transaction.serialize({ requireAllSignatures: false }).toString("base64"),
      signatureBase64: Buffer.from(rawSignature).toString("base64"),
      signerBase58: publicKey.toBase58(),
    };
  }
}
