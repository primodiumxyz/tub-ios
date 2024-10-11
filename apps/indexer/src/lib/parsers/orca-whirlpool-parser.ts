import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { struct, u8, union } from "@solana/buffer-layout";
// @ts-expect-error buffer-layout-utils is not typed
import { u64, u128 } from "@solana/buffer-layout-utils";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

type SwapArgs = {
  amount: bigint;
  otherAmountThreshold: bigint;
  sqrtPriceLimit: bigint;
  amountSpecifiedIsInput: boolean;
  aToB: boolean;
};

const SwapArgsLayout = struct<SwapArgs>([
  u64("amount"),
  u64("otherAmountThreshold"),
  u128("sqrtPriceLimit"),
  u8("amountSpecifiedIsInput"),
  u8("aToB"),
]);

type TwoHopSwapArgs = {
  amount: bigint;
  otherAmountThreshold: bigint;
  amountSpecifiedIsInput: boolean;
  aToBOne: boolean;
  aToBTwo: boolean;
  sqrtPriceLimitOne: bigint;
  sqrtPriceLimitTwo: bigint;
};

const TwoHopSwapArgsLayout = struct<TwoHopSwapArgs>([
  u64("amount"),
  u64("otherAmountThreshold"),
  u8("amountSpecifiedIsInput"),
  u8("aToBOne"),
  u8("aToBTwo"),
  u128("sqrtPriceLimitOne"),
  u128("sqrtPriceLimitTwo"),
]);

// TODO: remainingAccountsInfo
// https://solscan.io/account/whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc#anchorProgramIdl
// type SwapV2Args = {
//   amount: bigint;
//   otherAmountThreshold: bigint;
//   amountSpecifiedIsInput: boolean;
//   aToB: boolean;
//   remainingAccountsInfo: number;
// };

// const SwapV2ArgsLayout = struct<SwapV2Args>([
//   u64("amount"),
//   u64("otherAmountThreshold"),
//   u8("amountSpecifiedIsInput"),
//   u8("aToB"),
//   union(u8(), null, "remainingAccountsInfo"),
// ]);

// TODO: remainingAccountsInfo
// https://solscan.io/account/whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc#anchorProgramIdl
// type TwoHopSwapV2Args = {
//   amount: bigint;
//   otherAmountThreshold: bigint;
//   amountSpecifiedIsInput: boolean;
//   aToBOne: boolean;
//   aToBTwo: boolean;
//   sqrtPriceLimitOne: bigint;
//   sqrtPriceLimitTwo: bigint;
//   remainingAccountsInfo: number;
// };

// const TwoHopSwapV2ArgsLayout = struct<TwoHopSwapV2Args>([
//   u64("amount"),
//   u64("otherAmountThreshold"),
//   u8("amountSpecifiedIsInput"),
//   u8("aToBOne"),
//   u8("aToBTwo"),
//   u128("sqrtPriceLimitOne"),
//   u128("sqrtPriceLimitTwo"),
//   union(u8(), null, "remainingAccountsInfo"),
// ]);

// TODO(discriminator): twoHopSwap, twoHopSwapV2
export class OrcaWhirlpoolParser {
  static PROGRAM_ID = new PublicKey("whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc");
  static DISCRIMINATORS = {
    swap: 14449647541112719096n,
    swapV2: 7070309578724672555n,
  };

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const discriminator = u64().decode(instructionData);

    switch (discriminator) {
      case OrcaWhirlpoolParser.DISCRIMINATORS.swap: {
        return this.parseSwapIx(instruction);
      }
      case OrcaWhirlpoolParser.DISCRIMINATORS.swapV2: {
        return this.parseSwapV2Ix(instruction);
      }
      // we're not interested in any other instructions
      default:
        return this.parseUnknownInstruction(instruction);
    }
  }

  private parseSwapIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapArgsLayout.decode(instructionData); // Skip the first byte (instruction discriminator)

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "tokenProgram";
          break;
        case 1:
          name = "tokenAuthority";
          break;
        case 2:
          name = "whirlpool";
          break;
        case 3:
          name = "tokenOwnerAccountA";
          break;
        case 4:
          name = "tokenVaultA";
          break;
        case 5:
          name = "tokenOwnerAccountB";
          break;
        case 6:
          name = "tokenVaultB";
          break;
        case 7:
          name = "tickArray0";
          break;
        case 8:
          name = "tickArray1";
          break;
        case 9:
          name = "tickArray2";
          break;
        case 10:
          name = "oracle";
          break;
        default:
          name = `unknown${index}`;
      }
      return { ...account, name };
    });

    return {
      name: "swap",
      accounts: parsedAccounts,
      args: {
        amount: Number(args.amount),
        otherAmountThreshold: Number(args.otherAmountThreshold),
        sqrtPriceLimit: Number(args.sqrtPriceLimit),
        amountSpecifiedIsInput: args.amountSpecifiedIsInput,
        aToB: args.aToB,
      },
      programId: instruction.programId,
    };
  }

  private parseTwoHopSwapIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = TwoHopSwapArgsLayout.decode(instructionData);

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "tokenProgram";
          break;
        case 1:
          name = "tokenAuthority";
          break;
        case 2:
          name = "whirlpoolOne";
          break;
        case 3:
          name = "whirlpoolTwo";
          break;
        case 4:
          name = "tokenOwnerAccountOneA";
          break;
        case 5:
          name = "tokenVaultOneA";
          break;
        case 6:
          name = "tokenOwnerAccountOneB";
          break;
        case 7:
          name = "tokenVaultOneB";
          break;
        case 8:
          name = "tokenOwnerAccountTwoA";
          break;
        case 9:
          name = "tokenVaultTwoA";
          break;
        case 10:
          name = "tokenOwnerAccountTwoB";
          break;
        case 11:
          name = "tokenVaultTwoB";
          break;
        case 12:
          name = "tickArrayOne0";
          break;
        case 13:
          name = "tickArrayOne1";
          break;
        case 14:
          name = "tickArrayOne2";
          break;
        case 15:
          name = "tickArrayTwo0";
          break;
        case 16:
          name = "tickArrayTwo1";
          break;
        case 17:
          name = "tickArrayTwo2";
          break;
        case 18:
          name = "oracleOne";
          break;
        case 19:
          name = "oracleTwo";
          break;
        default:
          name = `unknown${index}`;
      }
      return { ...account, name };
    });

    return {
      name: "twoHopSwap",
      accounts: parsedAccounts,
      args: {
        amount: Number(args.amount),
        otherAmountThreshold: Number(args.otherAmountThreshold),
        amountSpecifiedIsInput: args.amountSpecifiedIsInput,
        aToBOne: args.aToBOne,
        aToBTwo: args.aToBTwo,
        sqrtPriceLimitOne: Number(args.sqrtPriceLimitOne),
        sqrtPriceLimitTwo: Number(args.sqrtPriceLimitTwo),
      },
      programId: instruction.programId,
    };
  }

  private parseSwapV2Ix(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    // const args = SwapV2ArgsLayout.decode(instructionData);

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "tokenProgramA";
          break;
        case 1:
          name = "tokenProgramB";
          break;
        case 2:
          name = "memoProgram";
          break;
        case 3:
          name = "tokenAuthority";
          break;
        case 4:
          name = "whirlpool";
          break;
        case 5:
          name = "tokenMintA";
          break;
        case 6:
          name = "tokenMintB";
          break;
        case 7:
          name = "tokenOwnerAccountA";
          break;
        case 8:
          name = "tokenVaultA";
          break;
        case 9:
          name = "tokenOwnerAccountB";
          break;
        case 10:
          name = "tokenVaultB";
          break;
        case 11:
          name = "tickArray0";
          break;
        case 12:
          name = "tickArray1";
          break;
        case 13:
          name = "tickArray2";
          break;
        case 14:
          name = "oracle";
          break;
        default:
          name = `unknown${index}`;
      }
      return { ...account, name };
    });

    return {
      name: "swapV2",
      accounts: parsedAccounts,
      args: {
        // amount: Number(args.amount),
        // otherAmountThreshold: Number(args.otherAmountThreshold),
        // amountSpecifiedIsInput: args.amountSpecifiedIsInput,
        // aToB: args.aToB,
        // remainingAccountsInfo: args.remainingAccountsInfo,
      },
      programId: instruction.programId,
    };
  }

  private parseTwoHopSwapV2Ix(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    // const args = TwoHopSwapV2ArgsLayout.decode(instructionData);

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "whirlpoolOne";
          break;
        case 1:
          name = "whirlpoolTwo";
          break;
        case 2:
          name = "tokenMintInput";
          break;
        case 3:
          name = "tokenMintIntermediate";
          break;
        case 4:
          name = "tokenMintOutput";
          break;
        case 5:
          name = "tokenProgramInput";
          break;
        case 6:
          name = "tokenProgramIntermediate";
          break;
        case 7:
          name = "tokenProgramOutput";
          break;
        case 8:
          name = "tokenOwnerAccountInput";
          break;
        case 9:
          name = "tokenVaultOneInput";
          break;
        case 10:
          name = "tokenVaultOneIntermediate";
          break;
        case 11:
          name = "tokenVaultTwoIntermediate";
          break;
        case 12:
          name = "tokenVaultTwoOutput";
          break;
        case 13:
          name = "tokenOwnerAccountOutput";
          break;
        case 14:
          name = "tokenAuthority";
          break;
        case 15:
          name = "tickArrayOne0";
          break;
        case 16:
          name = "tickArrayOne1";
          break;
        case 17:
          name = "tickArrayOne2";
          break;
        case 18:
          name = "tickArrayTwo0";
          break;
        case 19:
          name = "tickArrayTwo1";
          break;
        case 20:
          name = "tickArrayTwo2";
          break;
        case 21:
          name = "oracleOne";
          break;
        case 22:
          name = "oracleTwo";
          break;
        case 23:
          name = "memoProgram";
          break;
        default:
          name = `unknown${index}`;
      }
      return { ...account, name };
    });

    return {
      name: "twoHopSwapV2",
      accounts: parsedAccounts,
      args: {
        // amount: Number(args.amount),
        // otherAmountThreshold: Number(args.otherAmountThreshold),
        // amountSpecifiedIsInput: args.amountSpecifiedIsInput,
        // aToBOne: args.aToBOne,
        // aToBTwo: args.aToBTwo,
        // sqrtPriceLimitOne: Number(args.sqrtPriceLimitOne),
        // sqrtPriceLimitTwo: Number(args.sqrtPriceLimitTwo),
        // remainingAccountsInfo: args.remainingAccountsInfo,
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
