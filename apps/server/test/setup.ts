import { Keypair } from "@solana/web3.js";
import { config } from "dotenv";
import { resolve } from "path";
import bs58 from "bs58";
import { env } from "@bin/tub-server";

declare module "vitest" {
  export interface ProvidedContext {
    port: number;
    host: string;
  }
}

export default async function () {
  console.log("Setting up test environment");

  // Load test environment variables first
  config({
    path: resolve(__dirname, "../.env.test"),
  });

  // Generate and set private key if not already set
  if (!env.FEE_PAYER_PRIVATE_KEY) {
    const testKeypair = Keypair.generate();
    env.FEE_PAYER_PRIVATE_KEY = bs58.encode(testKeypair.secretKey);
  }

  // Set any missing required variables with defaults
  env.NODE_ENV = env.NODE_ENV || "test";
  env.JUPITER_URL = env.JUPITER_URL || "https://quote-api.jup.ag/v6";
  env.PRIVY_APP_ID = env.PRIVY_APP_ID || "dummy-privy-app-id";
  env.PRIVY_APP_SECRET = env.PRIVY_APP_SECRET || "dummy-privy-secret";
  env.OCTANE_TRADE_FEE_RECIPIENT = env.OCTANE_TRADE_FEE_RECIPIENT || "11111111111111111111111111111111";
  env.OCTANE_BUY_FEE = Number(env.OCTANE_BUY_FEE) || 100;
  env.OCTANE_SELL_FEE = Number(env.OCTANE_SELL_FEE) || 0;
  env.OCTANE_MIN_TRADE_SIZE = Number(env.OCTANE_MIN_TRADE_SIZE) || 15;
}
