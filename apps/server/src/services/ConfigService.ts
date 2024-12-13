import { z } from "zod";
import { PublicKey } from "@solana/web3.js";

// Define configuration schemas
const TokenConfig = z
  .object({
    USDC_DEV_PUBLIC_KEY: z.string(),
    USDC_MAINNET_PUBLIC_KEY: z.string(),
    SOL_MAINNET_PUBLIC_KEY: z.string(),
    VALUE_MAINNET_PUBLIC_KEY: z.string(),
    ATA_PROGRAM_PUBLIC_KEY: z.string(),
    TOKEN_PROGRAM_PUBLIC_KEY: z.string(),
    JUPITER_PROGRAM_PUBLIC_KEY: z.string(),
  })
  .strict();

const RegistryConfig = z
  .object({
    REGISTRY_TIMEOUT: z.number(),
    CLEANUP_INTERVAL: z.number(),
    SOL_USD_PRICE_UPDATE_INTERVAL: z.number(),
    RETRY_ATTEMPTS: z.number(),
    RETRY_DELAY: z.number(),
  })
  .strict();

const SwapConfig = z
  .object({
    USER_SLIPPAGE_BPS_MAX: z.number(),
    MAX_DEFAULT_SLIPPAGE_BPS: z.number(),
    AUTO_SLIPPAGE: z.boolean(),
    MAX_AUTO_SLIPPAGE_BPS: z.number(),
    MAX_ACCOUNTS: z.number(),
    AUTO_SLIPPAGE_COLLISION_USD_VALUE: z.number(),
    MIN_SLIPPAGE_BPS: z.number(),
    AUTO_PRIORITY_FEE_MULTIPLIER: z.number(),
  })
  .strict();

export type Config = {
  tokens: z.infer<typeof TokenConfig>;
  registry: z.infer<typeof RegistryConfig>;
  swap: z.infer<typeof SwapConfig>;
};

export class ConfigService {
  private static instance: ConfigService;
  private config: Config;

  private constructor() {
    this.config = {
      tokens: {
        USDC_DEV_PUBLIC_KEY: "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
        USDC_MAINNET_PUBLIC_KEY: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        SOL_MAINNET_PUBLIC_KEY: "So11111111111111111111111111111111111111112",
        VALUE_MAINNET_PUBLIC_KEY: "DcRHumYETnVKowMmDSXQ5RcGrFZFAnaqrQ1AZCHXpump",
        ATA_PROGRAM_PUBLIC_KEY: "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
        TOKEN_PROGRAM_PUBLIC_KEY: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
        JUPITER_PROGRAM_PUBLIC_KEY: "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
      },
      registry: {
        REGISTRY_TIMEOUT: 5 * 60 * 1000, // 5 minutes
        CLEANUP_INTERVAL: 60 * 1000, // 1 minute
        SOL_USD_PRICE_UPDATE_INTERVAL: 5 * 1000, // 5 seconds
        RETRY_ATTEMPTS: 10,
        RETRY_DELAY: 1000, // 1 second
      },
      swap: {
        USER_SLIPPAGE_BPS_MAX: 10000, // 10%
        MAX_DEFAULT_SLIPPAGE_BPS: 200, // 2%
        AUTO_SLIPPAGE: true,
        MAX_AUTO_SLIPPAGE_BPS: 200, // 2%
        MAX_ACCOUNTS: 50,
        AUTO_SLIPPAGE_COLLISION_USD_VALUE: 1000, // 1000 USD
        MIN_SLIPPAGE_BPS: 50,
        AUTO_PRIORITY_FEE_MULTIPLIER: 3,
      },
    };
  }

  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  public getConfig(): Config {
    return this.config;
  }

  public getSwapConfig(): z.infer<typeof SwapConfig> {
    return this.config.swap;
  }

  public getRegistryConfig(): z.infer<typeof RegistryConfig> {
    return this.config.registry;
  }

  public getTokenConfig(): z.infer<typeof TokenConfig> {
    return this.config.tokens;
  }

  public getPublicKey(tokenKey: keyof Config["tokens"]): PublicKey {
    return new PublicKey(this.config.tokens[tokenKey]);
  }

  // Separate update methods for each config section
  public updateTokenConfig(updates: Partial<Config["tokens"]>): void {
    const validated = TokenConfig.partial().parse(updates);
    this.config.tokens = { ...this.config.tokens, ...validated };
  }

  public updateRegistryConfig(updates: Partial<Config["registry"]>): void {
    const validated = RegistryConfig.partial().parse(updates);
    this.config.registry = { ...this.config.registry, ...validated };
  }

  public updateSwapConfig(updates: Partial<Config["swap"]>): void {
    const validated = SwapConfig.partial().parse(updates);
    this.config.swap = { ...this.config.swap, ...validated };
  }
}
