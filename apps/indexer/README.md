# server

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
| `ALCHEMY_RPC_URL`     | Alchemy RPC URL                 | `https://solana-mainnet.g.alchemy.com/v2/`    |
| `HELIUS_WS_URL`       | Helius WS URL                   | `wss://mainnet.helius-rpc.com/?api-key=`      |

## Adding a parser

1. Create the parser in `src/lib/parsers` (or a minimal parser in `src/lib/parsers/minimal`, meaning that it doesn't bother decoding args and accounts, just returning the swap accounts)
2. Add the program to `src/lib/constants.ts:PROGRAMS`
3. That's it!
