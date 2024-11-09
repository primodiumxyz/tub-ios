import { Connection, Keypair, PublicKey, Transaction } from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@primodiumxyz/octane-core";
import { TokenFee } from "./tokenFee";
import type { Cache } from 'cache-manager';

export class OctaneService {
  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
    private tradeFeeRecipient: PublicKey,
    private buyFee: number,
    private sellFee: number,
    private minTradeSize: number,
    private cache: Cache
  ) {}

  async signTransactionWithTokenFee(transaction: Transaction, buyBool: boolean, tokenMint: PublicKey, tokenDecimals: number): Promise<string> {
    try {
      const { signature } = await signWithTokenFee(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        [
            TokenFee.fromSerializable({
                mint: tokenMint.toString(),
                account: this.tradeFeeRecipient.toString(),
                decimals: tokenDecimals,
                fee: buyBool ? this.buyFee : this.sellFee
            })
        ],
        this.cache,
        2000 // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error signing transaction with token fee:", e);
      throw new Error("Failed to sign transaction with token fee");
    }
  }

  async createAccountWithTokenFee(transaction: Transaction, tokenMint: PublicKey, tokenDecimals: number): Promise<string> {
    try {
      const { signature } = await createAccountIfTokenFeePaid(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        [
            TokenFee.fromSerializable({
                mint: tokenMint.toString(),
                account: this.tradeFeeRecipient.toString(),
                decimals: tokenDecimals,
                fee: 0
            })
        ],
        this.cache,
        2000 // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error creating account with token fee:", e);
      throw new Error("Failed to create account with token fee");
    }
  }

  async validateTransactionInstructions(transaction: Transaction): Promise<void> {
    try {
      await core.validateInstructions(transaction, this.feePayerKeypair);
    } catch (e) {
      console.error("Error validating transaction instructions:", e);
      throw new Error("Invalid transaction instructions");
    }
  }
} 