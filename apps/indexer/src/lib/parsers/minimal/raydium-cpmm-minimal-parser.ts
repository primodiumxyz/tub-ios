// Copied and fixed from https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249
import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedAccount, ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { u8 } from "@solana/buffer-layout";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

export class RaydiumCpmmMinimalParser {
  static PROGRAM_ID = new PublicKey("CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C");
  static DISCRIMINATORS = {
    swapBaseInput: 143,
    swapBaseOutput: 55,
  };

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const discriminator = u8().decode(instructionData);

    switch (discriminator) {
      case RaydiumCpmmMinimalParser.DISCRIMINATORS.swapBaseInput: {
        return this.parseSwapBaseInputIx(instruction);
      }
      case RaydiumCpmmMinimalParser.DISCRIMINATORS.swapBaseOutput: {
        return this.parseSwapBaseOutputIx(instruction);
      }
      // we're not interested in other instructions
      default:
        return this.parseUnknownInstruction(instruction);
    }
  }

  private parseSwapBaseInputIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    return {
      name: "swapBaseInput",
      accounts: [
        {
          ...accounts[6],
          name: "vaultA",
        },
        {
          ...accounts[7],
          name: "vaultB",
        },
      ] as ParsedAccount[],
      args: {},
      programId: instruction.programId,
    };
  }

  private parseSwapBaseOutputIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    return {
      name: "swapBaseOutput",
      accounts: [
        {
          ...accounts[6],
          name: "vaultA",
        },
        {
          ...accounts[7],
          name: "vaultB",
        },
      ] as ParsedAccount[],
      args: {},
      programId: instruction.programId,
    };
  }

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  private parseUnknownInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const accounts = instruction.keys;
    return {
      name: "Unknown",
      accounts,
      args: { unknown: utils.bytes.bs58.encode(instruction.data) },
      programId: instruction.programId,
    };
  }
}
