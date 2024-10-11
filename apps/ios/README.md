# Tub iOS Client

The `apps/ios` directory contains the Tub iOS client, written in Swift and managed as an Xcode project. To get started, open this directory in Xcode 16 or above.

## GraphQL

The GraphQL types and schema are managed separately from the co-located TypeScript `@tub/gql` package in this repository. Instead, the iOS app uses Swift types generated with [`apollo-ios`](https://github.com/apollographql/apollo-ios)

### Setup

When the GraphQL schema is modified, the GraphQL schema will have to be re-fetched. First, check that the `endpointURL` field in `./apollo-codegen-config.json` is valid. If the referenced URL references `localhost`, launch the developer Hasura instance first from the `@tub/gql` package in `packages/gql`.

```json
{
  ...
  "schemaDownloadConfiguration": {
    "downloadMethod": {
      "introspection": {
        "endpointURL": "http://localhost:8080/v1/graphql",
        "httpMethod": {
          "POST": {}
        },
        "includeDeprecatedInputValues": false,
        "outputFormat": "SDL"
      }
    },
    "downloadTimeout": 60,
    "headers": [],
    "outputPath": "./graphql/schema.graphqls"
  }
  ...
}
```

Then, to fetch schema from the GraphQL server, run the following:

```
./apollo-ios-cli fetch-schema
```

This fetches the GraphQL schema to `./graphql/schema.graphqls`.

Then, write a new query in `./graphql/queries.graphql`.

```graphql
query GetAllAccounts {
  account {
    id
    username
    created_at
  }
}
```

Generate GraphQL Swift types with the following:

```
./apollo-ios-cli generate
```

See `Tub/Models` for examples of GraphQL query and subscription fetching.
