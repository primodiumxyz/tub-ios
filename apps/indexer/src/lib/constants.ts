import { PublicKey } from "@solana/web3.js";

// Helius Business plan has a limit of 200 req/s
// Solana has <3,500 TPS as of 2024-10-11 (of which ~1/10 are swaps)
// and we can include up to 100 accounts per RPC request (50 swaps)
// -> a batch size of 50 can accomodate up to 10,000 swaps/s
// AND 100M credits/month means ~38 credits/s
// vvv (if we only use getPoolTokenPrice.getMultipleParsedAccounts with the Helius RPC)
// -> so we can actually handle ~1,900 swaps/s to stay withing usage limits with this current plan
export const FETCH_DATA_BATCH_SIZE = 50; // this is the max batch size (50 * 2 accounts)
export const FETCH_HELIUS_WRITE_GQL_BATCH_SIZE = 20; // max 1k because we're fetching `getAssetBatch` from Helius and it has a limit of 1k
export const PRICE_PRECISION = 1e9;

export const WRAPPED_SOL_MINT = new PublicKey("So11111111111111111111111111111111111111112");
export const PUMP_FUN_AUTHORITY = new PublicKey("TSLvdd1pWpHVjahSpsvCXUbgwsL3JAcvokwaKt1eokM");

// Expected close codes for the websocket (restart straight away)
export const CLOSE_CODES = {
  MANUAL_RESTART: 3000,
  PING_TIMEOUT: 3001,
  NO_DATA: 3002,
};
