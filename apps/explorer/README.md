**Moving over to the Tub repo for a reference implementation, as this PoC is working, but needs to be separated into packages (server, db, api, ui).**

### References

1. Helius (min $499/month)

- enhanced websocket: needs at least business plan ($499/month)
  - subscribe to txs: https://docs.helius.dev/webhooks-and-websockets/enhanced-websockets
- parse txs: https://docs.helius.dev/solana-apis/enhanced-transactions-api/parse-transaction-s

2. Solana Tracker (min $247/month)

- shared Yellowstone Geyser for $247/month: https://www.solanatracker.io/solana-rpc
  - https://medium.com/@je.sse/helius-atlas-rpc-pool-whirligig-geyser-alternative-8d2a6c54397b

### Outdated

- [formatters](./src/lib/formatters) and [parsers](./src/lib/parsers) are copied and heavily fixed from [blog](https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249)/[replit](https://replit.com/@rex-god/get-parsed-instructions-of-raydium-amm#utils/transaction-formatter.ts)
