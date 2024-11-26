// Copied and fixed from https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249
import { Idl, utils } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { struct, u8 } from "@solana/buffer-layout";
// @ts-expect-error buffer-layout-utils is not typed
import { u64 } from "@solana/buffer-layout-utils";
import { AccountMeta, PublicKey, TransactionInstruction } from "@solana/web3.js";

export type SwapBaseInArgs = {
  discriminator: number;
  amountIn: bigint;
  minimumAmountOut: bigint;
};
const SwapBaseInArgsLayout = struct<SwapBaseInArgs>([u8("discriminator"), u64("amountIn"), u64("minimumAmountOut")]);

export type SwapBaseOutArgs = {
  discriminator: number;
  maxAmountIn: bigint;
  amountOut: bigint;
};
const SwapBaseOutArgsLayout = struct<SwapBaseOutArgs>([u8("discriminator"), u64("maxAmountIn"), u64("amountOut")]);

export type TransferInstruction = {
  amount: bigint;
};
const TransferInstructionLayout = struct<TransferInstruction>([u8("instruction"), u64("amount")]);

const parseSwapAccounts = (accounts: AccountMeta[]): AccountMeta[] => {
  // Transactions that go directly through Raydium include the 'ammTargetOrders' account
  // Otherwise, if they were made through Jupited, the Raydium AMM Routing program, or various other routes,
  // they won't include it.
  // We can pretty safely infer that with the amount of accounts in the transaction (as of 2024-10-02)
  // - if there are 18 accounts, it's a direct Raydium transaction
  // - if there are 17 accounts, it's a Jupiter transaction or routed through another program
  // a similar workaround is done here: https://github.com/Topledger/solana-programs/blob/main/dex-trades/src/dapps/dapp_675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8.rs
  const labels = [
    "tokenProgram",
    "amm",
    "ammAuthority",
    "ammOpenOrders",
    accounts.length === 18 ? "ammTargetOrders" : undefined,
    "poolCoinTokenAccount",
    "poolPcTokenAccount",
    "serumMarket",
    "serumBids",
    "serumAsks",
    "serumCoinVaultAccount",
    "serumPcVaultAccount",
    "serumVaultSigner",
    "serumReqQueue",
    "serumEventQueue",
    "userSourceTokenAccount",
    "uerDestinationTokenAccount",
    "userSourceOwner",
  ].filter(Boolean);

  return labels.map((label, index) => {
    if (!accounts[index]) throw new Error(`Account ${label} not found`);
    return { ...accounts[index], name: label };
  });
};

export class RaydiumAmmParser {
  static PROGRAM_ID = new PublicKey("675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8");
  static DISCRIMINATORS = {
    swapBaseIn: 9,
    swapBaseOut: 11,
  };

  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parseInstruction(instruction: TransactionInstruction): ParsedInstruction<Idl, string> {
    const instructionData = instruction.data;
    const discriminator = u8().decode(instructionData);

    // https://github.com/raydium-io/raydium-idl/blob/master/raydium_amm/src/program.ts
    switch (discriminator) {
      case RaydiumAmmParser.DISCRIMINATORS.swapBaseIn: {
        return this.parseSwapBaseInIx(instruction);
      }
      case RaydiumAmmParser.DISCRIMINATORS.swapBaseOut: {
        return this.parseSwapBaseOutIx(instruction);
      }
      // we're not interested in other instructions
      default:
        return this.parseUnknownInstruction(instruction);
    }
  }

  private parseSwapBaseInIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapBaseInArgsLayout.decode(instructionData);
    return {
      name: "swapBaseIn",
      accounts: parseSwapAccounts(accounts),
      args: {
        amountIn: BigInt(args.amountIn),
        minimumAmountOut: BigInt(args.minimumAmountOut),
      },
      programId: instruction.programId,
    };
  }

  private parseSwapBaseOutIx(instruction: TransactionInstruction) {
    const accounts = instruction.keys;
    const instructionData = instruction.data;
    const args = SwapBaseOutArgsLayout.decode(instructionData);
    return {
      name: "swapBaseOut",
      accounts: parseSwapAccounts(accounts),
      args: {
        maxAmountIn: BigInt(args.maxAmountIn),
        amountOut: BigInt(args.amountOut),
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

  static decodeTransferIxs(...instructions: TransactionInstruction[]) {
    return instructions.map((instruction) => {
      const dataBuffer = instruction.data;
      const decoded = TransferInstructionLayout.decode(dataBuffer);

      return {
        name: "transfer",
        accounts: instruction.keys,
        args: {
          amount: BigInt(decoded.amount),
          source: instruction.keys[0]!.pubkey,
          destination: instruction.keys[1]!.pubkey,
          authority: instruction.keys[2]!.pubkey,
        },
        programId: instruction.programId,
      };
    });
  }
}
