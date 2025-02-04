import { z } from "zod";
import { RedisService } from "./RedisService";
import defaultConfig from "../../default-redis-config.json";

/**
 * Zod schema for validating configuration
 * Defines and enforces types for all configuration values
 */
export const configSchema = z
  .object({
    CONFIG_UPDATE_INTERVAL: z.number(), // How often to refresh config from Redis (ms)
    REGISTRY_TIMEOUT: z.number(), // How long until registry entries expire (ms)
    CLEANUP_INTERVAL: z.number(), // How often to clean up expired entries (ms)
    SOL_USD_PRICE_UPDATE_INTERVAL: z.number(), // How often to fetch new SOL/USD price (ms)
    CONFIRM_ATTEMPTS: z.number(), // Max attempts to confirm a transaction
    CONFIRM_ATTEMPT_DELAY: z.number(), // Delay between confirmation attempts (ms)
    MAX_BUILD_ATTEMPTS: z.number(), // Max attempts per request to build a transactions
    MAX_SIM_ATTEMPTS: z.number(), // Max attempts per built transaction to simulate a transaction
    USER_SLIPPAGE_BPS_MAX: z.number(), // Maximum user-configurable slippage in basis points
    MAX_DEFAULT_SLIPPAGE_BPS: z.number(), // Default maximum slippage in basis points
    AUTO_SLIPPAGE: z.boolean(), // Whether to use automatic slippage adjustment
    MAX_AUTO_SLIPPAGE_BPS: z.number(), // Maximum auto-adjusted slippage in basis points
    MAX_ACCOUNTS: z.number(), // Maximum number of accounts to track per user
    AUTO_SLIPPAGE_COLLISION_USD_VALUE: z.number(), // USD threshold for slippage collision detection
    MIN_SLIPPAGE_BPS: z.number(), // Minimum slippage in basis points
    AUTO_PRIORITY_FEE_MULTIPLIER: z.number(), // Multiplier for automatic priority fee calculation
    MAX_COMPUTE_PRICE: z.number(), // Maximum compute units price allowed
    BUY_FEE_BPS: z.number(), // Fee for buy transactions in basis points
    SELL_FEE_BPS: z.number(), // Fee for sell transactions in basis points
    MIN_FEE_CENTS: z.number(), // Minimum fee in cents
    MIN_TRADE_SIZE_USD: z.number(), // Minimum trade size in USD
    TRADE_FEE_RECIPIENT: z.string(), // Pubkey to receive trading fees
    PUSH_REGISTRY_TIMEOUT_MS: z.number(), // How long until push registry entries expire (ms)
    PUSH_CLEANUP_INTERVAL_MS: z.number(), // How often to clean up push registry (ms)
    PUSH_SEND_INTERVAL_MS: z.number(), // How often to send push notifications (ms)
    REFRESH_TOKEN_ROLLING_STATS_30MIN_INTERVAL_SECONDS: z.number(), // How often to refresh token stats (seconds)
  })
  .strict();

/** Type definition for configuration object */
export type Config = z.infer<typeof configSchema>;

/**
 * Service for managing application configuration
 * Handles configuration validation, Redis synchronization, and provides access to config values
 */
export class ConfigService {
  private static instance: ConfigService;
  private redis = RedisService.getInstance().getClient();
  private readonly REDIS_KEY = "app:config";
  private localConfig: Config | null = null;
  private initialized = false;
  private startedInit = false;

  /**
   * Creates a new ConfigService instance
   * @private
   */
  private constructor() {
    this.init();
  }

  /**
   * Initializes the configuration service
   * Syncs with Redis and sets up periodic updates
   * @private
   * @throws Error if Redis connection or config initialization fails
   */
  private async init() {
    if (this.startedInit) {
      // delay 1 second to avoid race condition
      await new Promise((resolve) => setTimeout(resolve, 1000));
      return;
    }
    this.startedInit = true;
    console.log("Initializing ConfigService...");

    try {
      await this.syncWithRedis();
    } catch (e) {
      console.log("Initial sync failed:", e);

      // check if redis is running
      try {
        console.log("Checking Redis connection...");
        const redisStatus = await this.redis.ping();
        console.log("Redis status:", redisStatus);

        if (redisStatus !== "PONG") {
          throw new Error("Redis is not running");
        }

        // If Redis is running but config doesn't exist, set default configuration
        console.log("Redis is running but config not found. Setting default configuration...");
        await this.redis.set(this.REDIS_KEY, JSON.stringify(defaultConfig));
        console.log("Default config set. Attempting to sync again...");
        await this.syncWithRedis();
      } catch (error) {
        console.error("Redis connection error:", error);
        throw new Error("Failed to initialize Redis connection");
      }
    }

    this.startPeriodicSync();
    this.initialized = true;
  }

  /**
   * Gets the singleton instance of ConfigService
   * @returns Promise resolving to ConfigService instance
   */
  public static async getInstance(): Promise<ConfigService> {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
      await ConfigService.instance.init();
    }
    return ConfigService.instance;
  }

  /**
   * Gets the current configuration
   * @returns Current configuration object
   * @throws Error if config is not initialized
   */
  public getConfig(): Config {
    if (!this.initialized || !this.localConfig) {
      throw new Error("Config not initialized");
    }
    return this.localConfig;
  }

  /**
   * Synchronizes local configuration with Redis
   * @private
   * @throws Error if Redis config is missing or invalid
   */
  private async syncWithRedis() {
    const config = await this.redis.get(this.REDIS_KEY);
    if (!config) {
      throw new Error("Redis config not found");
    }

    const parsedConfig = JSON.parse(config);

    try {
      this.localConfig = configSchema.parse(parsedConfig);
    } catch (e) {
      console.error("Config validation failed:", e);
      throw new Error("Invalid config format in Redis");
    }
  }

  /**
   * Starts periodic synchronization with Redis
   * Updates local config at intervals specified in CONFIG_UPDATE_INTERVAL
   * @private
   */
  private startPeriodicSync() {
    setInterval(async () => {
      try {
        await this.syncWithRedis();
      } catch (e) {
        console.error("Failed to periodic sync with Redis:", e);
      }
    }, this.localConfig?.CONFIG_UPDATE_INTERVAL ?? 60_000);
  }
}
