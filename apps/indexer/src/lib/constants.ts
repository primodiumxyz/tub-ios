import { PublicKey } from "@solana/web3.js";

// Relative imports to not conflict with constants imports in other packages
import { MeteoraDlmmParser } from "./parsers/meteora-dlmm-parser";
import { MinimalParser } from "./parsers/minimal-parser";
import { OrcaWhirlpoolParser } from "./parsers/orca-whirlpool-parser";
import { RaydiumAmmParser } from "./parsers/raydium-amm-parser";
import { RaydiumClmmParser } from "./parsers/raydium-clmm-parser";
import { Program } from "./types";

// Helius Business plan has a limit of 200 req/s
// Solana has <3,500 TPS as of 2024-10-11 (of which ~1/10 are swaps)
// and we can include up to 100 accounts per RPC request (50 swaps)
// -> a batch size of 50 can accomodate up to 10,000 swaps/s
// AND 100M credits/month means ~38 credits/s
// vvv (if we only use getPoolTokenPrice.getMultipleParsedAccounts with the Helius RPC)
// -> so we can actually handle ~1,900 swaps/s to stay withing usage limits with this current plan
export const FETCH_PRICE_BATCH_SIZE = 50; // this is the max batch size (50 * 2 accounts)
export const WRITE_GQL_BATCH_SIZE = 300;
export const PRICE_PRECISION = 1e9;

export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");

// Discriminator and account indexes for minimal parsers come from this database:
// https://github.com/Topledger/solana-programs/tree/main/dex-trades/src/dapps
// Up to date with commit dbc8eab (2024-09-26)
export const PROGRAMS = [
  /* --------------------- PROGRAMS WITH DEDICATED PARSER --------------------- */
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
  /* ---------------------- PROGRAMS WITH MINIMAL PARSER ---------------------- */
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
  {
    id: "invariant-swap",
    publicKey: new PublicKey("HyaB3W9q6XdA5xwpU4XnSZV94htfmbmqJXZcEbRaJutt"),
    parser: new MinimalParser(new PublicKey("HyaB3W9q6XdA5xwpU4XnSZV94htfmbmqJXZcEbRaJutt"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [5, 6],
      },
    ]),
  },
  {
    id: "lifinity-swap-v2",
    publicKey: new PublicKey("2wT8Yq49kHgDzXuPxZSaeLaH1qbmGXtEyPy64bL7aD3c"),
    parser: new MinimalParser(new PublicKey("2wT8Yq49kHgDzXuPxZSaeLaH1qbmGXtEyPy64bL7aD3c"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [5, 6],
      },
    ]),
  },
  {
    id: "openbook-v2",
    publicKey: new PublicKey("opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb"),
    parser: new MinimalParser(new PublicKey("opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb"), [
      {
        name: "placeTakeOrder",
        discriminator: 3,
        accountIndexes: [11, 12],
      },
    ]),
  },
  {
    id: "phoenix",
    publicKey: new PublicKey("PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY"),
    parser: new MinimalParser(new PublicKey("PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY"), [
      {
        name: "swap",
        discriminator: 0,
        accountIndexes: [6, 7],
      },
    ]),
  },
  {
    id: "saber-stable-swap",
    publicKey: new PublicKey("SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ"),
    parser: new MinimalParser(new PublicKey("SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "orca-swap-v2",
    publicKey: new PublicKey("9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP"),
    parser: new MinimalParser(new PublicKey("9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "symmetry",
    publicKey: new PublicKey("2KehYt3KsEQR53jYcxjbQp2d2kCp4AkuQW68atufRwSr"),
    parser: new MinimalParser(new PublicKey("2KehYt3KsEQR53jYcxjbQp2d2kCp4AkuQW68atufRwSr"), [
      {
        name: "swapFundTokens",
        discriminator: 112,
        accountIndexes: [3, 5],
      },
    ]),
  },
  {
    id: "bonk-swap",
    publicKey: new PublicKey("BSwp6bEBihVLdqJRKGgzjcGLHkcTuzmSo1TQkHepzH8p"),
    parser: new MinimalParser(new PublicKey("BSwp6bEBihVLdqJRKGgzjcGLHkcTuzmSo1TQkHepzH8p"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "stepn-dooar",
    publicKey: new PublicKey("Dooar9JkhdZ7J3LHN3A7YCuoGRUggXhQaG4kijfLGU2j"),
    parser: new MinimalParser(new PublicKey("Dooar9JkhdZ7J3LHN3A7YCuoGRUggXhQaG4kijfLGU2j"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "fluxbeam",
    publicKey: new PublicKey("FLUXubRmkEi2q6K3Y9kBPg9248ggaZVsoSFhtJHSrm1X"),
    parser: new MinimalParser(new PublicKey("FLUXubRmkEi2q6K3Y9kBPg9248ggaZVsoSFhtJHSrm1X"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "saros-amm",
    publicKey: new PublicKey("SSwapUtytfBdBn1b9NUGG6foMVPtcWgpRU32HToDUZr"),
    parser: new MinimalParser(new PublicKey("SSwapUtytfBdBn1b9NUGG6foMVPtcWgpRU32HToDUZr"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "oasis",
    publicKey: new PublicKey("9tKE7Mbmj4mxDjWatikzGAtkoWosiiZX9y6J4Hfm2R8H"),
    parser: new MinimalParser(new PublicKey("9tKE7Mbmj4mxDjWatikzGAtkoWosiiZX9y6J4Hfm2R8H"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "crema-finance",
    publicKey: new PublicKey("CLMM9tUoggJu2wagPkkqs9eFG4BWhVBZWkP1qv3Sp7tR"),
    parser: new MinimalParser(new PublicKey("CLMM9tUoggJu2wagPkkqs9eFG4BWhVBZWkP1qv3Sp7tR"), [
      {
        name: "swapWithPartner",
        discriminator: 133,
        accountIndexes: [6, 7],
      },
    ]),
  },
  {
    id: "serum-dex-v3",
    publicKey: new PublicKey("9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin"),
    parser: new MinimalParser(new PublicKey("9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin"), [
      {
        name: "settleFunds",
        discriminator: 5,
        accountIndexes: [3, 4],
      },
    ]),
  },
  {
    id: "aldrin-amm",
    publicKey: new PublicKey("AMM55ShdkoGRB5jVYPjWziwk8m5MpwyDgsMWHaMSQWH6"),
    parser: new MinimalParser(new PublicKey("AMM55ShdkoGRB5jVYPjWziwk8m5MpwyDgsMWHaMSQWH6"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [3, 4],
      },
    ]),
  },
  {
    id: "openbook",
    publicKey: new PublicKey("srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX"),
    parser: new MinimalParser(new PublicKey("srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX"), [
      {
        name: "serum3PlaceOrder",
        discriminator: 10,
        accountIndexes: [8, 9],
      },
    ]),
  },
  {
    id: "orca-swap",
    publicKey: new PublicKey("DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1"),
    parser: new MinimalParser(new PublicKey("DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "cropper-finance",
    publicKey: new PublicKey("CTMAxxk34HjKWxQ3QLZK1HpaLXmBveao3ESePXbiyfzh"),
    parser: new MinimalParser(new PublicKey("CTMAxxk34HjKWxQ3QLZK1HpaLXmBveao3ESePXbiyfzh"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [5, 6],
      },
    ]),
  },
  {
    id: "aldrin-amm-v2",
    publicKey: new PublicKey("CURVGoZn8zycx6FXwwevgBTB2gVvdbGTEpvMJDbgs2t4"),
    parser: new MinimalParser(new PublicKey("CURVGoZn8zycx6FXwwevgBTB2gVvdbGTEpvMJDbgs2t4"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [3, 4],
      },
    ]),
  },
  {
    id: "balansol",
    publicKey: new PublicKey("D3BBjqUdCYuP18fNvvMbPAZ8DpcRi4io2EsYHQawJDag"),
    parser: new MinimalParser(new PublicKey("D3BBjqUdCYuP18fNvvMbPAZ8DpcRi4io2EsYHQawJDag"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [5, 8],
      },
    ]),
  },
  {
    id: "lifinity-swap",
    publicKey: new PublicKey("EewxydAPCCVuNEyrVN68PuSYdQ7wKn27V9Gjeoi8dy3S"),
    parser: new MinimalParser(new PublicKey("EewxydAPCCVuNEyrVN68PuSYdQ7wKn27V9Gjeoi8dy3S"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [5, 6],
      },
    ]),
  },
  {
    id: "penguin-finance",
    publicKey: new PublicKey("PSwapMdSai8tjrEXcxFeQth87xC4rRsa4VA5mhGhXkP"),
    parser: new MinimalParser(new PublicKey("PSwapMdSai8tjrEXcxFeQth87xC4rRsa4VA5mhGhXkP"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
  {
    id: "sencha",
    publicKey: new PublicKey("SCHAtsf8mbjyjiv4LkhLKutTf6JnZAbdJKFkXQNMFHZ"),
    parser: new MinimalParser(new PublicKey("SCHAtsf8mbjyjiv4LkhLKutTf6JnZAbdJKFkXQNMFHZ"), [
      {
        name: "swap",
        discriminator: 248,
        accountIndexes: [4, 7],
      },
    ]),
  },
  {
    id: "step-finance-swap",
    publicKey: new PublicKey("SSwpMgqNDsyV7mAgN9ady4bDVu5ySjmmXejXvy2vLt1"),
    parser: new MinimalParser(new PublicKey("SSwpMgqNDsyV7mAgN9ady4bDVu5ySjmmXejXvy2vLt1"), [
      {
        name: "swap",
        discriminator: 1,
        accountIndexes: [4, 5],
      },
    ]),
  },
] as const satisfies Program[];

export const PLATFORMS = PROGRAMS.map((program) => program.id);
