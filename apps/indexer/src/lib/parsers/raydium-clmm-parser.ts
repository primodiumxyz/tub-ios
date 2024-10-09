import { Idl, utils } from "@coral-xyz/anchor";
import { hash } from "@coral-xyz/anchor/dist/cjs/utils/sha256";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { struct, u8 } from "@solana/buffer-layout";
// @ts-expect-error buffer-layout-utils is not typed
import { u64, u128 } from "@solana/buffer-layout-utils";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

type SwapArgs = {
  amount: bigint;
  otherAmountThreshold: bigint;
  sqrtPriceLimitX64: bigint;
  isBaseInput: boolean;
};
const SwapArgsLayout = struct<SwapArgs>([
  u64("amount"),
  u64("otherAmountThreshold"),
  u128("sqrtPriceLimitX64"),
  u8("isBaseInput"),
]);

type SwapV2Args = SwapArgs;
const SwapV2ArgsLayout = SwapArgsLayout;

type SwapRouterBaseInArgs = {
  amountIn: bigint;
  amountOutMinimum: bigint;
};
const SwapRouterBaseInArgsLayout = struct<SwapRouterBaseInArgs>([u64("amountIn"), u64("amountOutMinimum")]);

export class RaydiumClmmParser {
  static PROGRAM_ID = new PublicKey("CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK");

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    // TODO: This doesn't make sense as the decoded type is not the index in the IDL; seems like the discriminator is encoded a different way;
    // how can we get from instruction name -> discriminator in this case? (or the opposite)
    const instructionType = u8().decode(instructionData);

    // 0: createAmmConfig
    // 1: updateAmmConfig
    // 2: createPool
    // 3: updatePoolStatus
    // 4: createOperationAccount
    // 5: updateOperationAccount
    // 6: transferRewardOwner
    // 7: initializeReward
    // 8: collectRemainingRewards
    // 9: updateRewardInfos
    // 10: setRewardsParams
    // 11: collectProtocolFee
    // 12: collectFundFee
    // 13: openPosition
    // 14: openPositionV2
    // 15: closePosition
    // 16: increaseLiquidity
    // 17: increaseLiquidityV2
    // 18: decreaseLiquidity
    // 19: decreaseLiquidityV2
    // 20: swap (=> 248)
    // 21: swapV2 (=> 43)
    // 22: swapRouterBaseIn

    switch (instructionType) {
      case 248: {
        return this.parseSwapIx(instruction);
      }
      case 43: {
        return this.parseSwapV2Ix(instruction);
      }
      // TODO: find out which number this one is
      case 22: {
        return this.parseSwapRouterBaseInIx(instruction);
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

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "payer";
          break;
        case 1:
          name = "ammConfig";
          break;
        case 2:
          name = "poolState";
          break;
        case 3:
          name = "inputTokenAccount";
          break;
        case 4:
          name = "outputTokenAccount";
          break;
        case 5:
          name = "inputVault";
          break;
        case 6:
          name = "outputVault";
          break;
        case 7:
          name = "observationState";
          break;
        case 8:
          name = "tokenProgram";
          break;
        case 9:
          name = "tickArray";
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
        sqrtPriceLimitX64: Number(args.sqrtPriceLimitX64),
        isBaseInput: args.isBaseInput,
      },
      programId: instruction.programId,
    };
  }

  private parseSwapV2Ix(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapV2ArgsLayout.decode(instructionData);

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "payer";
          break;
        case 1:
          name = "ammConfig";
          break;
        case 2:
          name = "poolState";
          break;
        case 3:
          name = "inputTokenAccount";
          break;
        case 4:
          name = "outputTokenAccount";
          break;
        case 5:
          name = "inputVault";
          break;
        case 6:
          name = "outputVault";
          break;
        case 7:
          name = "observationState";
          break;
        case 8:
          name = "tokenProgram";
          break;
        case 9:
          name = "tokenProgram2022";
          break;
        case 10:
          name = "memoProgram";
          break;
        case 11:
          name = "inputVaultMint";
          break;
        case 12:
          name = "outputVaultMint";
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
        amount: Number(args.amount),
        otherAmountThreshold: Number(args.otherAmountThreshold),
        sqrtPriceLimitX64: Number(args.sqrtPriceLimitX64),
        isBaseInput: args.isBaseInput,
      },
      programId: instruction.programId,
    };
  }

  private parseSwapRouterBaseInIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapRouterBaseInArgsLayout.decode(instructionData);

    const parsedAccounts = accounts.map((account, index) => {
      let name: string;
      switch (index) {
        case 0:
          name = "payer";
          break;
        case 1:
          name = "inputTokenAccount";
          break;
        case 2:
          name = "inputTokenMint";
          break;
        case 3:
          name = "tokenProgram";
          break;
        case 4:
          name = "tokenProgram2022";
          break;
        case 5:
          name = "memoProgram";
          break;
        default:
          name = `unknown${index}`;
      }
      return { ...account, name };
    });

    return {
      name: "swapRouterBaseIn",
      accounts: parsedAccounts,
      args: {
        amountIn: Number(args.amountIn),
        amountOutMinimum: Number(args.amountOutMinimum),
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
