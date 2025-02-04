import Redis from "ioredis";

import { env } from "@bin/tub-server";

/**
 * Service for managing Redis connection and operations Implements singleton pattern to ensure single Redis connection
 * across the application
 */
export class RedisService {
  private static instance: RedisService;
  private client: Redis;

  /**
   * Creates a new RedisService instance with configured connection
   *
   * @private
   */
  private constructor() {
    this.client = new Redis({
      host: env.REDIS_HOST,
      port: env.REDIS_PORT,
      password: env.REDIS_PASSWORD,
    });
  }

  /**
   * Gets the singleton instance of RedisService
   *
   * @returns RedisService instance
   */
  public static getInstance(): RedisService {
    if (!this.instance) {
      this.instance = new RedisService();
    }
    return this.instance;
  }

  /**
   * Gets the Redis client instance
   *
   * @returns Redis client
   */
  public getClient(): Redis {
    return this.client;
  }
}
