# Keeper

> [!DEPRECATED]
> This is deprecated in favor of using the indexer to get price feeds from Solana. This still can be used to simulate price changes quickly if Solana providers are not available.

Keeper is a TypeScript service designed to simulate and update token prices for the tub ecosystem.

## Description

It periodically updates token prices in the database, creating a dynamic environment for testing user behavior on various token prices.

## Features

- Simulates price changes for tokens
- Connects to a GraphQL backend for data management
- Configurable update interval and volatility

## Usage

To run the Keeper service:

```sh
pnpm start
```

## Configuration

The Keeper service can be configured using the following environment variables:

| Variable             | Description                                | Default                                |
|----------------------|--------------------------------------------|----------------------------------------|
| `NODE_ENV`           | Environment (dev, prod, test)              | `dev`                                  |
| `SERVER_HOST`        | Host that the server listens on            | `0.0.0.0`                              |
| `SERVER_PORT`        | Port that the server listens on            | `9999`                                 |
| `HASURA_ADMIN_SECRET`| Admin secret for Hasura GraphQL engine     | `password`                             |
| `GRAPHQL_URL`        | URL of the GraphQL endpoint                | `http://localhost:8080/v1/graphql`     |
| `PRIVATE_KEY`        | Private key for authentication (if needed) | (a default key is provided)            |

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
