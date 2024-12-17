import { z } from "zod";
import { RedisService } from "./RedisService";
import defaultConfig from "../../default-redis-config.json";

export const configSchema = z
  .object({
    CONFIG_UPDATE_INTERVAL: z.number(),
    REGISTRY_TIMEOUT: z.number(),
    CLEANUP_INTERVAL: z.number(),
    SOL_USD_PRICE_UPDATE_INTERVAL: z.number(),
    RETRY_ATTEMPTS: z.number(),
    RETRY_DELAY: z.number(),
    USER_SLIPPAGE_BPS_MAX: z.number(),
    MAX_DEFAULT_SLIPPAGE_BPS: z.number(),
    AUTO_SLIPPAGE: z.boolean(),
    MAX_AUTO_SLIPPAGE_BPS: z.number(),
    MAX_ACCOUNTS: z.number(),
    AUTO_SLIPPAGE_COLLISION_USD_VALUE: z.number(),
    MIN_SLIPPAGE_BPS: z.number(),
    AUTO_PRIORITY_FEE_MULTIPLIER: z.number(),
    BUY_FEE_BPS: z.number(),
    SELL_FEE_BPS: z.number(),
    MIN_TRADE_SIZE_USD: z.number(),
    TRADE_FEE_RECIPIENT: z.string(),
  })
  .strict();

export type Config = z.infer<typeof configSchema>;

export class ConfigService {
  private static instance: ConfigService;
  private redis = RedisService.getInstance().getClient();
  private readonly REDIS_KEY = "app:config";
  private localConfig: Config | null = null;
  private initialized = false;

  private constructor() {
    this.init();
  }

  private async init() {
    // Try to sync first
    try {
      await this.syncWithRedis();
    } catch (e) {
      console.log(e);
      // check if redis is running
      const redisStatus = await this.redis.ping();
      if (redisStatus !== "PONG") {
        throw new Error("Redis is not running");
      }
      // If sync fails, initialize with defaults
      console.log("Initializing Redis with default configuration...");
      await this.redis.set(this.REDIS_KEY, JSON.stringify(defaultConfig));
      await this.syncWithRedis();
    }

    this.startPeriodicSync();
    this.initialized = true;
  }

  public static async getInstance(): Promise<ConfigService> {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
      await ConfigService.instance.init();
    }
    return ConfigService.instance;
  }

  public getConfig(): Config {
    if (!this.initialized || !this.localConfig) {
      throw new Error("Config not initialized");
    }
    return this.localConfig;
  }

  private async syncWithRedis() {
    const config = await this.redis.get(this.REDIS_KEY);
    if (!config) {
      throw new Error("Redis config not found");
    }
    this.localConfig = JSON.parse(config) as Config;
  }

  private startPeriodicSync() {
    setInterval(() => {
      this.syncWithRedis();
    }, this.localConfig?.CONFIG_UPDATE_INTERVAL ?? 60_000);
  }
}
