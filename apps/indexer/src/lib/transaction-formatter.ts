// Copied and adapted from https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249
import { utils } from "@coral-xyz/anchor";
import { ParsedMessage, ParsedTransactionMeta, ParsedTransactionWithMeta, PublicKey } from "@solana/web3.js";

import { TransactionMessageData, TransactionMetaData, TransactionSubscriptionResult } from "@/lib/types";

export class TransactionFormatter {
  public formTransactionFromJson(data: TransactionSubscriptionResult, time: number): ParsedTransactionWithMeta {
    return {
      slot: data.slot,
      version: data.transaction.version,
      blockTime: time,
      meta: this.formMeta(data.transaction.meta),
      transaction: {
        signatures: data.transaction.transaction.signatures.map((s: string) =>
          utils.bytes.bs58.encode(Buffer.from(s, "base64")),
        ),
        message: this.formTxnMessage(data.transaction.transaction.message),
      },
    };
  }

  private formTxnMessage(message: TransactionMessageData): ParsedMessage {
    const accountKeys = message.accountKeys.map((key) => ({ ...key, pubkey: new PublicKey(key.pubkey) }));
    const addressTableLookups =
      message.addressTableLookups?.map((lookup) => ({
        ...lookup,
        accountKey: new PublicKey(lookup.accountKey),
      })) ?? [];

    return {
      accountKeys,
      addressTableLookups,
      recentBlockhash: utils.bytes.bs58.encode(Buffer.from(message.recentBlockhash, "base64")),
      instructions: message.instructions.map((ix) => ({
        ...ix,
        programId: new PublicKey(ix.programId),
        accounts: "accounts" in ix ? ix.accounts.map((a) => new PublicKey(a)) : [],
      })),
    };
  }

  private formMeta(meta: TransactionMetaData): ParsedTransactionMeta {
    return {
      err: meta.err,
      fee: meta.fee,
      preBalances: meta.preBalances,
      postBalances: meta.postBalances,
      preTokenBalances: meta.preTokenBalances ?? [],
      postTokenBalances: meta.postTokenBalances ?? [],
      logMessages: meta.logMessages ?? [],
      loadedAddresses: {
        writable: [],
        readonly: [],
      },
      innerInstructions: meta.innerInstructions.map((ix) => ({
        index: ix.index,
        instructions: ix.instructions.map((i) => ({
          ...i,
          programId: new PublicKey(i.programId),
          accounts: "accounts" in i ? i.accounts.map((a) => new PublicKey(a)) : [],
        })),
      })),
    };
  }
}
