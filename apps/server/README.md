# Tub Server

A TypeScript-based tRPC server for the Tub ecosystem, providing protected API endpoints for building and sponsoring user transactions on Solana.

> NOTE: This could be replaced by a future PR with protection with row level security so mutations can be done directly through the GraphQL API.

## Description

The Tub Server offers a set of tRPC endpoints for various operations centered around building user transactions and sponsoring the SOL required for chain execution fees. It uses Fastify as the underlying web server and integrates with a GraphQL backend for data management.

## Features

- tRPC-based API for type-safe client-server communication
- WebSocket support for real-time updates
- Integration with Hasura GraphQL backend
- JWT-based authentication

## Usage

To run the Tub Server:

```sh
pnpm start
```

### Example client

```ts
const server = createServerClient({
  httpUrl: "http://localhost:8888/trpc",
  wsUrl: "ws://localhost:8888/trpc",
  httpHeaders: () => {
    const jwtToken = useUserStore.getState().jwtToken;
    return {
      Authorization: `Bearer ${jwtToken}`,
    };
  },
});

const results = await server.registerNewUser.mutate({
  username: "test",
  airdropAmount: "100",
});
```

For examples in swift, see [Network.swift](../ios/Tub/Network.swift).

## Configuration

The server can be configured with the following environment variables:

| Variable              | Description                          | Default                     |
| --------------------- | ------------------------------------ | --------------------------- |
| `NODE_ENV`            | Environment (local, dev, test, prod) | `local`                     |
| `SERVER_HOST`         | Host that the server listens on      | `0.0.0.0`                   |
| `SERVER_PORT`         | Port that the server listens on      | `8888`                      |
| `HASURA_ADMIN_SECRET` | Admin secret for Hasura GraphQL      | `password`                  |
| `HASURA_URL`          | URL of the Hasura endpoint           | `http://localhost:8090`     |
| `PRIVATE_KEY`         | Private key for solana wallet        | (a default key is provided) |
| `JWT_SECRET`          | Secret for JWT signing               | `secret`                    |
| `JUPITER_URL`         | Endpoint for the Jupiter V6 Swap API |                             |

The server can be further configured with the following Redis variables in `default-redis-config.json`. Ensure that `TRADE_FEE_RECIPIENT` is set to the address of the account that will receive the trade fees.

## Development

To set up the project for development:

1. Ensure all server-related env variables are set.
1. If Redis is not installed, make sure that `NODE_ENV` is set to `local` in the root `.env` file for Redis to be installed in the `prepare` step of `pnpm install`. Refer to `prepare` script in `./package.json` for details.

1. Install dependencies:

   ```bash
   pnpm install
   ```

1. This `server` application depends on `redis-server`. In development, this `server` application is typically run via `pnpm run dev` or `pnpm run dev:fullstack` in the parent repository, which also starts a `redis-server`. The root `package.json` runs `pnpm dev`, which only starts the `nodemon` without Redis.

   To run this application in a standalone environment with Redis, run the following which starts both `redis-server` and the `server` application.

   ```bash
   pnpm dev:standalone
   ```

1. For testing:

   ```bash
   pnpm test
   ```

## API Endpoints

The server exposes the following tRPC endpoints:

### Query Procedures

1. `getStatus`

   - Description: Returns the current status of the server
   - Response: `{ status: number }`

1. `getSolUsdPrice`

   - Description: Returns the current SOL/USD price
   - Response: `number`

1. `getSolBalance`

   - Description: Gets user's SOL balance
   - Response: `number`

1. `getAllTokenBalances`

   - Description: Gets all token balances for user
   - Response: Array of token balances

1. `getTokenBalance`

   - Description: Gets balance for specific token
   - Input: `{ tokenMint: string }`

1. `fetchSwap`

   - Description: Fetches a constructed swap transaction for the user. This transaction will need to be signed by the user, then sent to the server via `submitSignedTransaction`.
   - Input: `{ buyTokenId: string, sellTokenId: string, sellQuantity: number, slippageBps?: number }`

1. `fetchPresignedSwap`

   - Description: Fetches swap transaction pre-signed by the server's fee payer. This transaction will need to be signed by the user but can be submitted to any Solana node.
   - Input: `{ buyTokenId: string, sellTokenId: string, sellQuantity: number }`

1. `getEstimatedTransferFee`

   - Description: Gets estimated fee for transferring USDC to a different address
   - Response: Fee estimate in USDC base units

1. `fetchTransferTx`
   - Description: Fetches a constructed transfer transaction for the user. This transaction will need to be signed by the user, then sent to the server via `submitSignedTransaction`.
   - Input: `{ toAddress: string, amount: string, tokenId: string }`

### Subscription Procedures

1. `subscribeSolPrice`

   - Description: Real-time SOL price updates
   - Response: Stream of price updates

1. `swapStream` [deprecated]
   - Description: Real-time swap quote updates. Currently deprecated and unused, but could be used in the future for real-time updates.
   - Input: `{ request: { buyTokenId: string, sellTokenId: string, sellQuantity: number } }`

### Mutation Procedures

1. `submitSignedTransaction`

   - Description: Submits a signed transaction to the server. This transaction will be sponsored by the server's fee payer and submitted to the Solana network.
   - Input: `{ signature: string, base64Transaction: string }`

2. `updateSwapRequest` [deprecated]

   - Description: Updates parameters for an existing swap stream's request
   - Input: `{ buyTokenId: string, sellTokenId: string, sellQuantity: number }`

3. `stopSwapStream` [deprecated]

   - Description: Stops an active swap stream
   - Response: void

4. `recordTokenPurchase`

   - Description: Records a token purchase event
   - Input: Client event data with token purchase details

5. `recordTokenSale`

   - Description: Records a token sale event
   - Input: Client event data with token sale details

6. `recordLoadingTime`

   - Description: Records app loading time metrics
   - Input: Client event data with timing details

7. `recordAppDwellTime`

   - Description: Records time spent in app
   - Input: Client event data with dwell time

8. `recordTokenDwellTime`

   - Description: Records time spent viewing a token
   - Input: Client event data with token and dwell time

9. `startLiveActivity`

   - Description: Starts live price tracking for a token
   - Input: `{ tokenMint: string, tokenPriceUsd: string, deviceToken: string, pushToken: string }`

10. `stopLiveActivity`
    - Description: Stops live price tracking
    - Response: `{ success: boolean }`

## Testing

Before running tests on the server, first create a `.env.test` file with the appropriate environment variables. See `example.env.test` for an example.

1. In the project root, run the following to start the server:

   ```bash
   pnpm dev
   ```

1. Then navigate to `apps/server` and use the following command to run tests:

   ```bash
   pnpm test
   ```

### Testing Transactions Setup

You can test transactions by running the `tub-service.test.ts` file.

1. You may need to manually remove any `.skip` flags from the tests you want to run. These are placed there to prevent the tests from being run on every commit.
1. Ensure that your `FEE_PAYER` has a few dollars worth of SOL in it to pay for the chain fees. If this is not met, the test transactions will fail.
1. Ensure that your `FEE_PAYER` has an existing USDC ATA that has a rent-exempt balance (currently 0.002039 SOL). If this is not met, the test transactions will fail.
1. Optionally, you can change the token being traded in the tests by editing `MEMECOIN_MAINNET_PUBLIC_KEY` in `src/constants/tokens.ts`.
1. Check that `pnpm dev` is still running, then run the test file in `apps/server` with the following command:

   ```bash
   pnpm test tub-service.test.ts
   ```
