# Documentation

A minimal Typescript server to listen to onchain trade transactions and parse them, in order to save prices of swapped tokens into a database.

## Usage

Install and run with:

```sh
pnpm start
```

Or run along with other packages from root dir with:

```sh
pnpm dev:pumping-tokens # this will also run an explorer
```

## Configuration

The server can be configured with the following environment variables (in root .env file):

| Variable              | Description                     | Default                                       |
| --------------------- | ------------------------------- | --------------------------------------------- |
| `NODE_ENV`            | Environment                     | `local`                                       |
| `SERVER_HOST`         | Host that the server listens on | `0.0.0.0`                                     |
| `SERVER_PORT`         | Port that the server listens on | `8888`                                        |
| `HASURA_ADMIN_SECRET` | Hasura admin secret             | `password`                                    |
| `GRAPHQL_URL`         | GraphQL URL                     | `https://tub-graphql.primodium.ai/v1/graphql` |
| `HELIUS_API_KEY`      | Helius API key                  |                                               |

## Adding a parser

1. Create the parser in `src/lib/parsers` (or a minimal parser in `src/lib/parsers/minimal`, meaning that it doesn't bother decoding args and accounts, just returning the swap accounts)
2. Add the program to `src/lib/constants.ts:PROGRAMS`
3. That's it!

# References

DISCRIMINATORS AND ACCOUNTS HERE: https://github.com/Topledger/solana-programs/tree/main/dex-trades/src/dapps

1. Helius (min $499/month)

- enhanced websocket: needs at least business plan ($499/month)
  - subscribe to txs: https://docs.helius.dev/webhooks-and-websockets/enhanced-websockets
- parse txs: https://docs.helius.dev/solana-apis/enhanced-transactions-api/parse-transaction-s

2. Solana Tracker (min $247/month)

- shared Yellowstone Geyser for $247/month: https://www.solanatracker.io/solana-rpc
  - https://medium.com/@je.sse/helius-atlas-rpc-pool-whirligig-geyser-alternative-8d2a6c54397b

3. Minimal library to parse transactions: https://github.com/ryoid/anchores/

- this provides some helpers to parse Jupiter swap transactions, where a lot of traffic is going through, which could help bypass some of the minor DEXes by directly decoding the Jupiter swap event; will see if it provides the pools addresses

### Outdated

- [formatters](./src/lib/formatters) and [parsers](./src/lib/parsers) are copied and heavily fixed from [blog](https://blogs.shyft.to/how-to-stream-and-parse-raydium-transactions-with-shyfts-grpc-network-b16d5b3af249)/[replit](https://replit.com/@rex-god/get-parsed-instructions-of-raydium-amm#utils/transaction-formatter.ts)
