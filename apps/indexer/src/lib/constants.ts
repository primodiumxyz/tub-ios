import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm-parser";
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
    parser: MeteoraDlmmParser,
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
    parser: OrcaWhirlpoolParser,
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
      // TODO: add twoHopSwapV2
      {
        name: "twoHopSwapV2",
        accounts: [],
      },
    ],
  },
  // {
  //   id: "raydium-lp-v4",
  //   publicKey: RaydiumAmmParser.PROGRAM_ID,
  //   parser: RaydiumAmmParser,
  //   swaps: [
  //     {
  //       name: "swapBaseIn",
  //       accounts: [["poolCoinTokenAccount", "poolPcTokenAccount"]],
  //     },
  //     {
  //       name: "swapBaseOut",
  //       accounts: [["poolCoinTokenAccount", "poolPcTokenAccount"]],
  //     },
  //   ],
  // },
  {
    id: "raydium-clmm",
    publicKey: RaydiumClmmParser.PROGRAM_ID,
    parser: RaydiumClmmParser,
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
] as const satisfies Program[];

export const PLATFORMS = PROGRAMS.map((program) => program.id);
export const LOG_FILTERS = PROGRAMS.map((program) => program.publicKey.toString());
