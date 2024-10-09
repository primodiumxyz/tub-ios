// Copied and fixed from https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249
import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedAccount, ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { u8 } from "@solana/buffer-layout";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

import { SwapInstructionDetails } from "@/lib/types";

/**
 * A universal parser that doesn't bother parsing args and labeled accounts, but only extracts the two involved vaults.
 */
export class MinimalParser {
  programId: PublicKey;
  swapInstructions: SwapInstructionDetails[];

  constructor(programId: PublicKey, swapInstructions: SwapInstructionDetails[]) {
    this.programId = programId;
    this.swapInstructions = swapInstructions;
  }

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const discriminator = u8().decode(instructionData);

    const swapInstruction = this.swapInstructions.find((i) => i.discriminator === discriminator);
    if (!swapInstruction) return this.parseUnknownInstruction(instruction);

    const accounts = instruction.keys;
    return {
      name: swapInstruction.name,
      accounts: [
        {
          ...accounts[swapInstruction.accountIndexes[0]],
          name: "vaultA",
        },
        {
          ...accounts[swapInstruction.accountIndexes[1]],
          name: "vaultB",
        },
      ] as ParsedAccount[],
      args: {},
      programId: instruction.programId,
    };
  }

  public getSwapInstructionNames(): string[] {
    return this.swapInstructions.map((i) => i.name);
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
