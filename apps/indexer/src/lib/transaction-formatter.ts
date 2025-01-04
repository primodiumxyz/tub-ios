import { utils } from "@coral-xyz/anchor";
import {
  ConfirmedTransactionMeta,
  Message,
  MessageV0,
  PublicKey,
  TokenBalance,
  VersionedMessage,
  VersionedTransactionResponse,
} from "@solana/web3.js";
import { SubscribeUpdateTransaction } from "@triton-one/yellowstone-grpc";
import {
  TokenBalance as TokenBalanceGrpc,
  Transaction,
  TransactionStatusMeta,
} from "@triton-one/yellowstone-grpc/dist/grpc/solana-storage";

export class TransactionFormatter {
  public formTransactionFromJson(
    data: SubscribeUpdateTransaction,
    time: number,
  ): VersionedTransactionResponse | undefined {
    const rawTx = data["transaction"];

    const slot = data.slot;
    const version = rawTx?.transaction?.message?.versioned ? 0 : "legacy";

    const meta = this.formMeta(rawTx?.meta);
    if (!meta) return;
    const signatures = rawTx?.transaction?.signatures.map((s: Uint8Array) => utils.bytes.bs58.encode(s));

    const message = this.formTxnMessage(rawTx?.transaction?.message);
    if (!message) return;

    return {
      slot: Number(slot),
      version,
      blockTime: time,
      meta,
      transaction: {
        signatures: signatures ?? [],
        message,
      },
    };
  }

  private formTxnMessage(message: Transaction["message"]): VersionedMessage | undefined {
    if (!message) return;
    if (!message.versioned) {
      return new Message({
        header: {
          numRequiredSignatures: message.header?.numRequiredSignatures ?? 0,
          numReadonlySignedAccounts: message.header?.numReadonlySignedAccounts ?? 0,
          numReadonlyUnsignedAccounts: message.header?.numReadonlyUnsignedAccounts ?? 0,
        },
        recentBlockhash: utils.bytes.bs58.encode(message.recentBlockhash),
        accountKeys: message.accountKeys?.map((d: Uint8Array) => utils.bytes.bs58.encode(d)),
        instructions: message.instructions.map(
          ({ data, programIdIndex, accounts }: { data: Uint8Array; programIdIndex: number; accounts: Uint8Array }) => ({
            programIdIndex: programIdIndex,
            accounts: [...accounts],
            data: utils.bytes.bs58.encode(data),
          }),
        ),
      });
    } else {
      return new MessageV0({
        header: {
          numRequiredSignatures: message.header?.numRequiredSignatures ?? 0,
          numReadonlySignedAccounts: message.header?.numReadonlySignedAccounts ?? 0,
          numReadonlyUnsignedAccounts: message.header?.numReadonlyUnsignedAccounts ?? 0,
        },
        recentBlockhash: utils.bytes.bs58.encode(message.recentBlockhash),
        staticAccountKeys: message.accountKeys.map((k: Uint8Array) => new PublicKey(utils.bytes.bs58.encode(k))),
        compiledInstructions: message.instructions.map(
          ({ programIdIndex, accounts, data }: { programIdIndex: number; accounts: Uint8Array; data: Uint8Array }) => ({
            programIdIndex: programIdIndex,
            accountKeyIndexes: [...accounts],
            data: data,
          }),
        ),
        addressTableLookups:
          message.addressTableLookups?.map(
            ({
              accountKey,
              writableIndexes,
              readonlyIndexes,
            }: {
              accountKey: any;
              writableIndexes: any;
              readonlyIndexes: any;
            }) => ({
              writableIndexes: writableIndexes || [],
              readonlyIndexes: readonlyIndexes || [],
              accountKey: new PublicKey(Buffer.from(accountKey, "base64")),
            }),
          ) || [],
      });
    }
  }

  private formMeta(meta: TransactionStatusMeta | undefined): ConfirmedTransactionMeta | undefined {
    if (!meta) return;
    return {
      err: meta.err ?? null,
      fee: Number(meta.fee),
      preBalances: meta.preBalances.map(Number),
      postBalances: meta.postBalances.map(Number),
      preTokenBalances: meta.preTokenBalances.map(this.formTokenBalance),
      postTokenBalances: meta.postTokenBalances.map(this.formTokenBalance),
      logMessages: meta.logMessages || [],
      loadedAddresses:
        meta.loadedWritableAddresses || meta.loadedReadonlyAddresses
          ? {
              writable:
                meta.loadedWritableAddresses?.map(
                  (address: Uint8Array) => new PublicKey(utils.bytes.bs58.encode(address)),
                ) || [],
              readonly:
                meta.loadedReadonlyAddresses?.map(
                  (address: Uint8Array) => new PublicKey(utils.bytes.bs58.encode(address)),
                ) || [],
            }
          : undefined,
      innerInstructions:
        meta.innerInstructions?.map((i: { index: number; instructions: any }) => ({
          index: i.index || 0,
          instructions: i.instructions.map((instruction: any) => ({
            programIdIndex: instruction.programIdIndex,
            accounts: [...instruction.accounts],
            data: utils.bytes.bs58.encode(Buffer.from(instruction.data || "", "base64")),
          })),
        })) || [],
    };
  }

  private formTokenBalance(balance: TokenBalanceGrpc): TokenBalance {
    return {
      ...balance,
      uiTokenAmount: balance.uiTokenAmount ?? {
        amount: "0",
        decimals: 0,
        uiAmount: 0,
      },
    };
  }
}
