# Tub Server

A TypeScript-based tRPC server for the tub ecosystem, providing protected API endpoints for making database mutations.

> NOTE: This will most likely be replaced by protected with row level security in the future so mutations can be done directly through the GraphQL API.

## Description

The Tub Server offers a set of tRPC endpoints for various operations. It uses Fastify as the underlying web server and integrates with a GraphQL backend for data management.

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

| Variable               | Description                          | Default                            |
| ---------------------- | ------------------------------------ | ---------------------------------- |
| `NODE_ENV`             | Environment (local, dev, test, prod) | `local`                            |
| `SERVER_HOST`          | Host that the server listens on      | `0.0.0.0`                          |
| `SERVER_PORT`          | Port that the server listens on      | `8888`                             |
| `HASURA_ADMIN_SECRET`  | Admin secret for Hasura GraphQL      | `password`                         |
| `GRAPHQL_URL`          | URL of the GraphQL endpoint          | `http://localhost:8080/v1/graphql` |
| `PRIVATE_KEY`          | Private key for solana wallet        | (a default key is provided)        |
| `JWT_SECRET`           | Secret for JWT signing               | `secret`                           |
| `JUPITER_API_ENDPOINT` | Endpoint for the Jupiter V6 Swap API |                                    |

## Development

To set up the project for development:

1. Install dependencies:

   ```
   pnpm install
   ```

2. Run in development mode:

   ```
   pnpm start
   ```

3. For testing:
   ```
   pnpm test
   ```

## API Endpoints

The server exposes the following tRPC endpoints:

### Query Procedures

1. `getStatus`
   - Description: Returns the current status of the server
   - Response: `{ status: number }`

### Mutation Procedures

1. `incrementCall`

   - Description: Increments a counter
   - Response: void

2. `registerNewUser`

   - Description: Registers a new user and returns a JWT token
   - Input: `{ username: string }`

3. `registerNewToken`

   - Description: Registers a new token
   - Input: `{ name: string, symbol: string, supply: string, uri: string }`

4. `airdropNativeToUser`

   - Description: Airdrops native tokens to a user
   - Input: `{ amount: string }`

5. `buyToken`

   - Description: Buys a token with the specified amount
   - Input: `{ tokenId: string, amount: string }`

6. `sellToken`

   - Description: Sells a token with the specified amount
   - Input: `{ tokenId: string, amount: string }`

7. `refreshToken`
   - Description: Refreshes a JWT token
   - Input: `{ userId: string }`
