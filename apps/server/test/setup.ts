import { Keypair } from "@solana/web3.js";
import { config } from "dotenv";
import { resolve } from "path";
import bs58 from "bs58";

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
  if (!process.env.FEE_PAYER_PRIVATE_KEY) {
    const testKeypair = Keypair.generate();
    process.env.FEE_PAYER_PRIVATE_KEY = bs58.encode(testKeypair.secretKey);
  }

  // Set any missing required variables with defaults
  process.env.NODE_ENV = process.env.NODE_ENV || "test";
  process.env.QUICKNODE_ENDPOINT =
    process.env.QUICKNODE_ENDPOINT || "https://blue-hardworking-paper.solana-mainnet.quiknode.pro";
  process.env.JUPITER_URL = process.env.JUPITER_URL || "https://quote-api.jup.ag/v6";
  process.env.PRIVY_APP_ID = process.env.PRIVY_APP_ID || "dummy-privy-app-id";
  process.env.PRIVY_APP_SECRET = process.env.PRIVY_APP_SECRET || "dummy-privy-secret";
  process.env.OCTANE_TRADE_FEE_RECIPIENT = process.env.OCTANE_TRADE_FEE_RECIPIENT || "11111111111111111111111111111111";
  process.env.OCTANE_BUY_FEE = process.env.OCTANE_BUY_FEE || "100";
  process.env.OCTANE_SELL_FEE = process.env.OCTANE_SELL_FEE || "0";
  process.env.OCTANE_MIN_TRADE_SIZE = process.env.OCTANE_MIN_TRADE_SIZE || "15";
}
