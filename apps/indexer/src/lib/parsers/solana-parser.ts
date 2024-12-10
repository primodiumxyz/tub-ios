// Copied and cleaned up from @shyft-to/solana-tx-parser-public
// Also to avoid errors probably due to cyclical dependencies: "TypeError: (0 , codecs_strings_1.getStringCodec) is not a function"
// - replaced BN with BigInt (BN not compatible with node)

import { BorshInstructionCoder, Idl } from "@coral-xyz/anchor";
import {
  compiledInstructionToInstruction,
  flattenParsedTransaction,
  flattenTransactionResponse,
  IdlAccountItem,
  InstructionNames,
  InstructionParserInfo,
  InstructionParsers,
  ParsedIdlArgs,
  ParsedInstruction,
  parsedInstructionToInstruction,
  ParserFunction,
  parseTransactionAccounts,
  ParsedInstruction as SolanaParsedInstruction,
  UnknownInstruction,
} from "@shyft-to/solana-transaction-parser";
import {
  AccountMeta,
  Connection,
  Finality,
  LoadedAddresses,
  Message,
  ParsedMessage,
  ParsedTransactionWithMeta,
  PartiallyDecodedInstruction,
  PublicKey,
  Transaction,
  TransactionInstruction,
  VersionedMessage,
  VersionedTransactionResponse,
} from "@solana/web3.js";

import { flattenIdlAccounts } from "@/lib/parsers/helpers";
import { TransactionWithParsed } from "@/lib/types";

const MEMO_PROGRAM_V1 = "Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo";
const MEMO_PROGRAM_V2 = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr";

/**
 * Class for parsing arbitrary solana transactions in various formats
 * - by txHash
 * - from raw transaction data (base64 encoded or buffer)
 * - @solana/web3.js getTransaction().message object
 * - @solana/web3.js getParsedTransaction().message or Transaction.compileMessage() object
 * - @solana/web3.js TransactionInstruction object
 */
export class SolanaParser {
  private instructionParsers: InstructionParsers;
  private instructionDecoders: Map<PublicKey | string, BorshInstructionCoder>;
  /**
   * Initializes parser object
   */
  constructor() {
    this.instructionDecoders = new Map();
    this.instructionParsers = new Map();
  }

  /**
   * Adds (or updates) parser for provided programId
   * @param programId program id to add parser for
   * @param parser parser to parse programId instructions
   */
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  addParser(programId: PublicKey, parser: ParserFunction<Idl, string>) {
    this.instructionParsers.set(programId.toBase58(), parser);
  }

  /**
   * Adds (or updates) parser for provided programId
   * @param programId program id to add parser for
   * @param idl IDL that describes anchor program
   */
  addParserFromIdl(programId: PublicKey | string, idl: Idl) {
    this.instructionDecoders.set(programId, new BorshInstructionCoder(idl));
    this.instructionParsers.set(...this.buildIdlParser(programId, idl));
  }

  isParserAvailable(programId: PublicKey | string): boolean {
    return this.instructionParsers.has(programId);
  }

  retrieveParserReadyProgramIds(): Array<string> {
    const programIds = Array.from(this.instructionParsers.keys());
    return programIds.map((key) => key.toString());
  }

  private buildIdlParser(programId: PublicKey | string, idl: Idl): InstructionParserInfo {
    // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
    const idlParser: ParserFunction<typeof idl, InstructionNames<typeof idl>> = (
      instruction: TransactionInstruction,
      decoder: BorshInstructionCoder,
    ) => {
      const parsedIx = decoder?.decode(instruction.data);
      if (!parsedIx) {
        return this.buildUnknownParsedInstruction(instruction.programId, instruction.keys, instruction.data);
      } else {
        const ix = idl.instructions.find((instr) => instr.name === parsedIx.name);
        if (!ix) {
          return this.buildUnknownParsedInstruction(
            instruction.programId,
            instruction.keys,
            instruction.data,
            parsedIx.name,
          );
        }
        const flatIdlAccounts = flattenIdlAccounts(<IdlAccountItem[]>ix.accounts);
        const accounts = instruction.keys.map((meta, idx) => {
          if (idx < flatIdlAccounts.length) {
            return {
              name: flatIdlAccounts[idx]?.name,
              ...meta,
            };
          }
          // "Remaining accounts" are unnamed in Anchor.
          else {
            return {
              name: `Remaining ${idx - flatIdlAccounts.length}`,
              ...meta,
            };
          }
        });

        return {
          name: parsedIx.name,
          accounts,
          programId: instruction.programId,
          // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
          args: parsedIx.data as ParsedIdlArgs<typeof idl, (typeof idl)["instructions"][number]["name"]>, // as IxArgsMap<typeof idl, typeof idl["instructions"][number]["name"]>,
        };
      }
    };

    return [programId, idlParser.bind(this)];
  }

  /**
   * Removes parser for provided program id
   * @param programId program id to remove parser for
   */
  removeParser(programId: PublicKey) {
    this.instructionParsers.delete(programId.toBase58());
  }

  private buildUnknownParsedInstruction(
    programId: PublicKey,
    accounts: AccountMeta[],
    argData: unknown,
    name?: string,
  ): UnknownInstruction {
    return {
      programId,
      accounts,
      args: { unknown: argData },
      name: name || "unknown",
    };
  }

  /**
   * Parses instruction
   * @param instruction transaction instruction to parse
   * @returns parsed transaction instruction or UnknownInstruction
   */
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction<I extends Idl, IxName extends InstructionNames<I>>(
    instruction: TransactionInstruction,
    // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  ): ParsedInstruction<I, IxName> {
    if (!this.instructionParsers.has(instruction.programId.toBase58())) {
      return this.buildUnknownParsedInstruction(instruction.programId, instruction.keys, instruction.data);
    } else {
      try {
        // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
        const parser = this.instructionParsers.get(instruction.programId.toBase58()) as ParserFunction<I, IxName>;
        const decoder = this.instructionDecoders.get(instruction.programId.toBase58()) as BorshInstructionCoder;

        // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
        return parser(instruction, decoder);
      } catch {
        console.error("Parser does not match the instruction args", {
          programId: instruction.programId.toBase58(),
          instructionData: instruction.data.toString("hex"),
        });

        return this.buildUnknownParsedInstruction(instruction.programId, instruction.keys, instruction.data);
      }
    }
  }

  /**
   * Parses transaction data along with inner instructions
   * @param tx response to parse
   * @returns list of parsed instructions
   */
  parseTransactionWithInnerInstructions<T extends VersionedTransactionResponse>(tx: T): TransactionWithParsed[] {
    const flattened = flattenTransactionResponse(tx);

    return flattened.map(({ parentProgramId, ...ix }) => {
      const parsedIx = this.parseInstruction(ix);
      if (parentProgramId) {
        parsedIx.parentProgramId = parentProgramId;
      }

      return { raw: ix, parsed: parsedIx };
    });
  }

  /**
   * Parses transaction data
   * @param txMessage message to parse
   * @param altLoadedAddresses VersionedTransaction.meta.loaddedAddresses if tx is versioned
   * @returns list of parsed instructions
   */
  parseTransactionData<T extends Message | VersionedMessage>(
    txMessage: T,
    altLoadedAddresses: T extends VersionedMessage ? LoadedAddresses | undefined : undefined = undefined,
    // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  ): ParsedInstruction<Idl, string>[] {
    const parsedAccounts = parseTransactionAccounts(txMessage, altLoadedAddresses);

    return txMessage.compiledInstructions.map((instruction) =>
      this.parseInstruction(compiledInstructionToInstruction(instruction, parsedAccounts)),
    );
  }

  /**
   * Parses transaction data retrieved from Connection.getParsedTransaction
   * @param txParsedMessage message to parse
   * @returns list of parsed instructions
   */
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseTransactionParsedData(txParsedMessage: ParsedMessage): ParsedInstruction<Idl, string>[] {
    const parsedAccounts = txParsedMessage.accountKeys.map((metaLike) => ({
      isSigner: metaLike.signer,
      isWritable: metaLike.writable,
      pubkey: metaLike.pubkey,
    }));

    return txParsedMessage.instructions.map((parsedIx) =>
      this.parseInstruction(parsedInstructionToInstruction(parsedIx as PartiallyDecodedInstruction, parsedAccounts)),
    );
  }

  /**
   * Parses transaction data retrieved from Connection.getParsedTransaction along with the inner instructions
   * @param txParsedMessage message to parse
   * @returns list of parsed instructions
   */
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseParsedTransactionWithInnerInstructions(txn: ParsedTransactionWithMeta): ParsedInstruction<Idl, string>[] {
    const allInstructions = flattenParsedTransaction(txn);
    const parsedAccounts = txn.transaction.message.accountKeys.map((metaLike) => ({
      isSigner: metaLike.signer,
      isWritable: metaLike.writable,
      pubkey: metaLike.pubkey,
    }));

    return allInstructions.map(({ parentProgramId, ...instruction }) => {
      // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
      let parsedIns: ParsedInstruction<Idl, string>;
      if ("data" in instruction) {
        parsedIns = this.parseInstruction(parsedInstructionToInstruction(instruction, parsedAccounts));
      } else {
        parsedIns = this.convertSolanaParsedInstruction(instruction);
      }

      if (parentProgramId) {
        parsedIns.parentProgramId = parentProgramId;
      }

      return parsedIns;
    });
  }

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  convertSolanaParsedInstruction(instruction: SolanaParsedInstruction): ParsedInstruction<Idl, string> {
    const parsed = instruction.parsed as { type: string; info: unknown };

    const pId = instruction.programId.toBase58();
    if (pId === MEMO_PROGRAM_V2 || pId === MEMO_PROGRAM_V1) {
      return {
        name: "Memo",
        programId: instruction.programId,
        args: { message: parsed },
        accounts: [],
      };
    }

    return {
      name: parsed.type,
      programId: instruction.programId,
      args: parsed.info,
      accounts: [],
    };
  }

  /**
   * Fetches tx from blockchain and parses it
   * @param connection web3 Connection
   * @param txId transaction id
   * @param flatten - true if CPI calls need to be parsed too
   * @returns list of parsed instructions
   */
  async parseTransaction(
    connection: Connection,
    txId: string,
    flatten: boolean = false,
    commitment: Finality = "confirmed",
    // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  ): Promise<ParsedInstruction<Idl, string>[] | null> {
    const transaction = await connection.getTransaction(txId, {
      commitment: commitment,
      maxSupportedTransactionVersion: 0,
    });
    if (!transaction) return null;
    if (flatten) {
      const flattened = flattenTransactionResponse(transaction);

      return flattened.map((ix) => this.parseInstruction(ix));
    }

    return this.parseTransactionData(transaction.transaction.message, transaction.meta?.loadedAddresses);
  }

  /**
   * Parses transaction dump
   * @param txDump base64-encoded string or raw Buffer which contains tx dump
   * @returns list of parsed instructions
   */
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseTransactionDump(txDump: string | Buffer): ParsedInstruction<Idl, string>[] {
    if (!(txDump instanceof Buffer)) txDump = Buffer.from(txDump, "base64");
    const tx = Transaction.from(txDump);
    const message = tx.compileMessage();

    return this.parseTransactionData(message);
  }
}
