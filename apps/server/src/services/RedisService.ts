import Redis from "ioredis";
import { env } from "../../bin/tub-server";

export class RedisService {
  private static instance: RedisService;
  private client: Redis;

  private constructor() {
    this.client = new Redis({
      host: env.REDIS_HOST,
      port: env.REDIS_PORT,
      password: env.REDIS_PASSWORD,
    });
  }

  public static getInstance(): RedisService {
    if (!RedisService.instance) {
      RedisService.instance = new RedisService();
    }
    return RedisService.instance;
  }

  public getClient(): Redis {
    return this.client;
  }
}
