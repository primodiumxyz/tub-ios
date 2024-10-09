import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm-parser";
import { MinimalParser } from "./parsers/minimal-parser";
import { OrcaWhirlpoolParser } from "./parsers/orca-whirlpool-parser";
import { RaydiumAmmParser } from "./parsers/raydium-amm-parser";
import { RaydiumClmmParser } from "./parsers/raydium-clmm-parser";
import { Program } from "./types";

export const PRICE_DATA_BATCH_SIZE = 300;
export const PRICE_PRECISION = 1e9;

export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

export const PROGRAMS = [
  {
    id: "meteora-dlmm",
    publicKey: MeteoraDlmmParser.PROGRAM_ID,
    parser: new MeteoraDlmmParser(),
    swaps: [
      {
        name: "swap",
        accounts: [["tokenXMint", "tokenYMint"]],
      },
      {
        name: "swapExactOut",
        accounts: [["tokenXMint", "tokenYMint"]],
      },
      {
        name: "swapWithPriceImpact",
        accounts: [["tokenXMint", "tokenYMint"]],
      },
    ],
  },
  {
    id: "orca-whirlpool",
    publicKey: OrcaWhirlpoolParser.PROGRAM_ID,
    parser: new OrcaWhirlpoolParser(),
    swaps: [
      {
        name: "swap",
        accounts: [["tokenVaultA", "tokenVaultB"]],
      },
      {
        name: "twoHopSwap",
        accounts: [
          ["tokenVaultOneA", "tokenVaultOneB"],
          ["tokenVaultTwoA", "tokenVaultTwoB"],
        ],
      },
      {
        name: "swapV2",
        accounts: [["tokenVaultA", "tokenVaultB"]],
      },
      // TODO: add twoHopSwapV2 if there are some accounts we can use
      {
        name: "twoHopSwapV2",
        accounts: [],
      },
    ],
  },
  {
    id: "raydium-lp-v4",
    publicKey: RaydiumAmmParser.PROGRAM_ID,
    parser: new RaydiumAmmParser(),
    swaps: [
      {
        name: "swapBaseIn",
        accounts: [["poolCoinTokenAccount", "poolPcTokenAccount"]],
      },
      {
        name: "swapBaseOut",
        accounts: [["poolCoinTokenAccount", "poolPcTokenAccount"]],
      },
    ],
  },
  {
    id: "raydium-clmm",
    publicKey: RaydiumClmmParser.PROGRAM_ID,
    parser: new RaydiumClmmParser(),
    swaps: [
      {
        name: "swap",
        accounts: [["inputVault", "outputVault"]],
      },
      {
        name: "swapV2",
        accounts: [["inputVault", "outputVault"]],
      },
      // TODO: add swapRouterBaseIn
      {
        name: "swapRouterBaseIn",
        accounts: [],
      },
    ],
  },
  {
    id: "raydium-cpmm",
    publicKey: new PublicKey("CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C"),
    parser: new MinimalParser(new PublicKey("CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C"), [
      {
        name: "swapBaseInput",
        discriminator: 143,
        accountIndexes: [6, 7],
      },
      {
        name: "swapBaseOutput",
        discriminator: 55,
        accountIndexes: [6, 7],
      },
    ]),
  },
  {
    id: "meteora-pools",
    publicKey: new PublicKey("Eo7WjKq67rjJQSZxS6z3YkapzY3eMj6Xy8X5EQVn5UaB"),
    parser: new MinimalParser(new PublicKey("Eo7WjKq67rjJQSZxS6z3YkapzY3eMj6Xy8X5EQVn5UaB"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [5, 6],
      },
    ]),
  },
] as const satisfies Program[];

export const PLATFORMS = PROGRAMS.map((program) => program.id);
export const LOG_FILTERS = PROGRAMS.map((program) => program.publicKey.toString());
