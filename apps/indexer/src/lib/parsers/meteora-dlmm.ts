import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { s32, struct, u8, u16, union } from "@solana/buffer-layout";
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

type SwapWithPriceImpactArgs = {
  amountIn: bigint;
  activeId: number | null;
  maxPriceImpactBps: number;
};
const SwapWithPriceImpactArgsLayout = struct<SwapWithPriceImpactArgs>([
  u64("amountIn"),
  // TODO: is this correct? are we correctly parsing such swaps?
  // https://github.com/MeteoraAg/dlmm-sdk/blob/b0813754a2749e403f8d5230e068f57b619f34ca/ts-client/src/dlmm/idl.ts#L6530C9-L6535C11
  union(u8(), null, "activeId"),
  u16("maxPriceImpactBps"),
]);

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

export class MeteoraDlmmParser {
  static PROGRAM_ID = new PublicKey("LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo");

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const instructionType = u8().decode(instructionData);

    //github.com/MeteoraAg/dlmm-sdk/blob/b0813754a2749e403f8d5230e068f57b619f34ca/ts-client/src/dlmm/idl.ts#L6530C9-L6535C11
    // Instructions:
    // 0: initializeLbPair
    // 2: initializePermissionLbPair
    // 3: initializeBinArrayBitmapExtension
    // 4: initializeBinArray
    // 5: addLiquidity
    // 6: addLiquidityByWeight
    // 7: addLiquidityByStrategy
    // 8: addLiquidityByStrategyOneSide
    // 9: addLiquidityOneSide
    // 10: removeLiquidity
    // 11: initializePosition
    // 12: initializePositionPda
    // 13: initializePositionByOperator
    // 14: updatePositionOperator
    // 15: swap
    // 16: swapExactOut
    // 17: swapWithPriceImpact
    // 18: withdrawProtocolFee
    // 19: initializeReward
    // 20: fundReward
    // 21: updateRewardFunder
    // 22: updateRewardDuration
    // 23: claimReward
    // 24: claimFee
    // 25: closePosition
    // 26: updateFeeParameters
    // 27: increaseOracleLength
    // 28: initializePresetParameter
    // 29: closePresetParameter
    // 30: removeAllLiquidity
    // 31: removeLiquiditySingleSide
    // 32: togglePairStatus
    // 33: updateWhitelistedWallet
    // 34: migratePosition
    // 35: migrateBinArray
    // 36: updateFeesAndRewards
    // 37: withdrawIneligibleReward
    // 38: setActivationPoint
    // 39: setLockReleasePoint
    // 40: removeLiquidityByRange
    // 41: addLiquidityOneSidePrecise
    // 42: goToABin
    // 43: setPreActivationDuration
    // 44: setPreActivationSwapAddress

    https: switch (instructionType) {
      case 15: {
        return this.parseSwapIx(instruction);
      }
      case 16: {
        return this.parseSwapExactOutIx(instruction);
      }
      case 17: {
        return this.parseSwapWithPriceImpactIx(instruction);
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
    const args = SwapWithPriceImpactArgsLayout.decode(instructionData);
    return {
      name: "swapWithPriceImpact",
      accounts: parseSwapAccounts(accounts),
      args: {
        amountIn: Number(args.amountIn),
        activeId: args.activeId,
        maxPriceImpactBps: args.maxPriceImpactBps,
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
