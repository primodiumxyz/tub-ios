# GraphQL package

**A type-safe GraphQL client for querying DEX trades and tokens, built on a Hasura backend and supercharged with TimescaleDB, for optimized time-series capabilities.**

See [the original README of the library](https://github.com/primodiumxyz/dex-indexer-stack/packages/gql) for the entire documentation.

This forks adds analytics to the `default` database, as well as GraphQL operations to query and mutate these analytics.

## Usage

Start the whole database stack with:

```bash
cd packages/gql
pnpm dev
```

Or from root along with the rest of the stack:

```bash
pnpm dev
```

Another addition here are the scripts to extract GraphQL operations [from the TypeScript definitions](./src/graphql/) and generate similar files in GraphQL for consumption by the iOS app.

```bash
# From root
pnpm sync:gql:ios
```

```bash
# From gql package
pnpm extract-mutations
pnpm extract-queries
pnpm extract-subscriptions
```

## Contributing

If you wish to contribute to the package, please open an issue first to make sure that this is within the scope of the library, and that it is not already being worked on.

## License

This project is licensed under the MIT License - see [LICENSE](../../LICENSE) for details.
