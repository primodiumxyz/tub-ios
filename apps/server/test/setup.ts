import { config } from "dotenv";
import { resolve } from "path";
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

  // Throw error if FEE_PAYER_PRIVATE_KEY is not set
  if (!env.FEE_PAYER_PRIVATE_KEY) {
    throw new Error("FEE_PAYER_PRIVATE_KEY is not set");
  }

  // Set any missing required variables with defaults
  env.NODE_ENV = env.NODE_ENV || "test";
  env.JUPITER_URL = env.JUPITER_URL || "https://quote-api.jup.ag/v6";
  env.PRIVY_APP_ID = env.PRIVY_APP_ID || "dummy-privy-app-id";
  env.PRIVY_APP_SECRET = env.PRIVY_APP_SECRET || "dummy-privy-secret";
}
