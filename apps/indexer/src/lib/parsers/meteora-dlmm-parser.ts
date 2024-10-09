import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { struct, u8, u16, union } from "@solana/buffer-layout";
// @ts-expect-error buffer-layout-utils is not typed
import { u64 } from "@solana/buffer-layout-utils";
import { AccountMeta, PublicKey, TransactionInstruction } from "@solana/web3.js";

type SwapArgs = {
  amountIn: bigint;
  minAmountOut: bigint;
};
const SwapArgsLayout = struct<SwapArgs>([u64("amountIn"), u64("minAmountOut")]);

type SwapExactOutArgs = {
  maxInAmount: bigint;
  outAmount: bigint;
};
const SwapExactOutArgsLayout = struct<SwapExactOutArgs>([u64("maxInAmount"), u64("outAmount")]);

// TODO: parsing activeId
// https://github.com/MeteoraAg/dlmm-sdk/blob/b0813754a2749e403f8d5230e068f57b619f34ca/ts-client/src/dlmm/idl.ts#L6530C9-L6535C11
// type SwapWithPriceImpactArgs = {
//   amountIn: bigint;
//   activeId: number | null;
//   maxPriceImpactBps: number;
// };
// const SwapWithPriceImpactArgsLayout = struct<SwapWithPriceImpactArgs>([
//   u64("amountIn"),
//   union(u8(), null, "activeId"),
//   u16("maxPriceImpactBps"),
// ]);

const parseSwapAccounts = (accounts: AccountMeta[]): AccountMeta[] => {
  const labels = [
    "lbPair",
    "binArrayBitmapExtension",
    "reserveX",
    "reserveY",
    "userTokenIn",
    "userTokenOut",
    "tokenXMint",
    "tokenYMint",
    "oracle",
    "hostFeeIn",
    "user",
    "tokenXProgram",
    "tokenYProgram",
    "eventAuthority",
    "program",
  ];

  return accounts.map((account, index) => {
    return { ...account, name: labels[index] };
  });
};

// TODO(discriminator): swapExactOut, swapWithPriceImpact
export class MeteoraDlmmParser {
  static PROGRAM_ID = new PublicKey("LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo");
  static DISCRIMINATORS = {
    swap: 248,
  };

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const discriminator = u8().decode(instructionData);

    switch (discriminator) {
      case MeteoraDlmmParser.DISCRIMINATORS.swap: {
        return this.parseSwapIx(instruction);
      }
      // we're not interested in any other instructions
      default:
        return this.parseUnknownInstruction(instruction);
    }
  }

  private parseSwapIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapArgsLayout.decode(instructionData);
    return {
      name: "swap",
      accounts: parseSwapAccounts(accounts),
      args: {
        amountIn: Number(args.amountIn),
        minAmountOut: Number(args.minAmountOut),
      },
      programId: instruction.programId,
    };
  }

  private parseSwapExactOutIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapExactOutArgsLayout.decode(instructionData);
    return {
      name: "swapExactOut",
      accounts: parseSwapAccounts(accounts),
      args: {
        maxInAmount: Number(args.maxInAmount),
        outAmount: Number(args.outAmount),
      },
      programId: instruction.programId,
    };
  }

  private parseSwapWithPriceImpactIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    // const args = SwapWithPriceImpactArgsLayout.decode(instructionData);
    return {
      name: "swapWithPriceImpact",
      accounts: parseSwapAccounts(accounts),
      args: {
        // amountIn: Number(args.amountIn),
        // activeId: args.activeId,
        // maxPriceImpactBps: args.maxPriceImpactBps,
      },
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
