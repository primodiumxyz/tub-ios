import { Connection, Keypair, Transaction } from "@solana/web3.js";
import { core, signWithTokenFee, createAccountIfTokenFeePaid } from "@solana/octane-core";
import { TokenFee } from "./tokenFee";
import type { Cache } from 'cache-manager';

export class OctaneService {
  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
    private allowedTokens: TokenFee[],
    private cache: Cache
  ) {}

  async signBuyTransactionWithTokenFee(transaction: Transaction): Promise<string> {
    try {
      const { signature } = await signWithTokenFee(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        this.allowedTokens,
        this.cache,
        2000 // sameSourceTimeout
      );

      return signature;
    } catch (e) {
      console.error("Error signing transaction with token fee:", e);
      throw new Error("Failed to sign transaction with token fee");
    }
  }

  async createAccountWithTokenFee(transaction: Transaction): Promise<string> {
    try {
      const { signature } = await createAccountIfTokenFeePaid(
        this.connection,
        transaction,
        this.feePayerKeypair,
        2, // maxSignatures
        5000, // lamportsPerSignature
        this.allowedTokens,
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