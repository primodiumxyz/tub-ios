import { utils } from "@coral-xyz/anchor";
import {
  CompiledInstruction,
  ConfirmedTransactionMeta,
  Message,
  MessageV0,
  PublicKey,
  VersionedMessage,
  VersionedTransactionResponse,
} from "@solana/web3.js";

export class TransactionFormatter {
  public formTransactionFromJson(data: VersionedTransactionResponse, time: number): VersionedTransactionResponse {
    const slot = data.slot;
    const version = data.transaction.message.version;

    const meta = data.meta ? this.formMeta(data.meta) : null;
    const signatures = data.transaction.signatures.map((s: string) =>
      utils.bytes.bs58.encode(Buffer.from(s, "base64")),
    );

    const message = this.formTxnMessage(data.transaction.message);

    return {
      slot,
      version,
      blockTime: time,
      meta,
      transaction: {
        signatures,
        message,
      },
    };
  }

  private formTxnMessage(message: VersionedTransactionResponse["transaction"]["message"]): VersionedMessage {
    if (message.version === "legacy") {
      return new Message({
        header: {
          numRequiredSignatures: message.header.numRequiredSignatures,
          numReadonlySignedAccounts: message.header.numReadonlySignedAccounts,
          numReadonlyUnsignedAccounts: message.header.numReadonlyUnsignedAccounts,
        },
        recentBlockhash: utils.bytes.bs58.encode(Buffer.from(message.recentBlockhash, "base64")),
        accountKeys: message.accountKeys,
        instructions: message.instructions.map(
          ({ data, programIdIndex, accounts }: { data: string; programIdIndex: number; accounts: number[] }) => ({
            programIdIndex: programIdIndex,
            accounts,
            data: utils.bytes.bs58.encode(Buffer.from(data || "", "base64")),
          }),
        ),
      });
    } else {
      return new MessageV0({
        header: {
          numRequiredSignatures: message.header.numRequiredSignatures,
          numReadonlySignedAccounts: message.header.numReadonlySignedAccounts,
          numReadonlyUnsignedAccounts: message.header.numReadonlyUnsignedAccounts,
        },
        recentBlockhash: utils.bytes.bs58.encode(Buffer.from(message.recentBlockhash, "base64")),
        staticAccountKeys: message.staticAccountKeys,
        compiledInstructions: message.compiledInstructions,
        addressTableLookups:
          message.addressTableLookups?.map(
            ({
              accountKey,
              writableIndexes,
              readonlyIndexes,
            }: {
              accountKey: PublicKey;
              writableIndexes: number[];
              readonlyIndexes: number[];
            }) => ({
              writableIndexes: writableIndexes || [],
              readonlyIndexes: readonlyIndexes || [],
              accountKey,
            }),
          ) || [],
      });
    }
  }

  private formMeta(meta: ConfirmedTransactionMeta): ConfirmedTransactionMeta {
    return {
      err: meta.err,
      fee: meta.fee,
      preBalances: meta.preBalances,
      postBalances: meta.postBalances,
      preTokenBalances: meta.preTokenBalances || [],
      postTokenBalances: meta.postTokenBalances || [],
      logMessages: meta.logMessages || [],
      loadedAddresses: meta.loadedAddresses ?? {
        writable: [],
        readonly: [],
      },
      innerInstructions:
        meta.innerInstructions?.map((i: { index: number; instructions: CompiledInstruction[] }) => ({
          index: i.index || 0,
          instructions: i.instructions.map((instruction) => ({
            programIdIndex: instruction.programIdIndex,
            accounts: instruction.accounts,
            data: utils.bytes.bs58.encode(Buffer.from(instruction.data || "", "base64")),
          })),
        })) || [],
    };
  }
}
