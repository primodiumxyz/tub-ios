# Tub iOS Client

The `/apps/ios` repository contains the Tub iOS client, written in Swift and managed as an Xcode project. To get started, open this directory in Xcode 16 or above.

## Development

Open the `/apps/ios` directory in Xcode with `File > Open`. The main Xcode project file is `Tub.xcodeproj`.

Then, run the application with `Product > Run`. If you don't have a set destination for the iOS app, set a build destination with `Product > Destination` to either a tethered iOS device or an iOS simulator.

## Colors

In arguments that expect a color, the `Color` object can be omitted when referring to a default system color. For example, `Color.red` can be used in `.foregroundStyle()` as `.foregroundStyle(.red)`.

All colors in this app is listed in `/apps/ios/Tub/Assets.xcasset`. Of all the customizable colors, only `AccentColor` is referred using the dot color shorthand of `.accent`.

For text, always use `.primary` and `.secondary` as colors, which match up with the system color scheme. For elements such as buttons, use `.tubPrimary` and `.tubSecondary` instead.

All other colors are referred as `.tubColorName`. For example, to refer to the `tubError` color, use `.tubError`.

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

## Distribution

First, create an archive in Xcode with `Product > Archive`. The following window will pop up.

<img width="1136" alt="image" src="https://github.com/user-attachments/assets/1344da75-85ae-444a-86b5-a15c6d9a9098">

Select a build and click on `Distribute App`.

<img width="1136" alt="image" src="https://github.com/user-attachments/assets/60b448c3-9057-4aac-83e7-85d9b10030cf">

For _App Store_ or _External Testflight_, select `App Store Connect`. For _TestFlight Internal Testing_, select `TestFlight Internal Only`. Click on `Distribute` to upload the build to App Store Connect.
