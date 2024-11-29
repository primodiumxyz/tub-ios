# GQL Package

The GQL package is a GraphQL client implementation for interacting with a Hasura-based backend. It provides a type-safe and efficient way to perform queries, mutations, and subscriptions.

## Features

- Type-safe GraphQL operations using `gql.tada`
- Support for queries, mutations, and subscriptions
- Automatic generation of GraphQL schema
- Integration with Hasura backend
- Test suite for GraphQL operations

## Installation

To install the package, run:

```bash
pnpm install @tub/gql
```

## Usage

### Creating a Client

To create a GraphQL client:

```typescript
import { createClient } from "@tub/gql";

const gql = await createClient({
  url: "http://localhost:8080/v1/graphql",
  hasuraAdminSecret: "your-admin-secret",
});
```

### Performing Operations

#### Queries

```typescript
const result = await gql.db.GetAllTokensQuery();
```

#### Mutations

```typescript
const result = await gql.db.RegisterNewUserMutation({
  amount: "1000000000000000000",
  username: "test_user",
});
```

#### Subscriptions

```typescript
const subscription = gql.db.GetLatestTokensSubscription({
  limit: 10,
});

subscription.subscribe({
  next: (result) => {
    console.log(result.data);
  },
  error: (error) => {
    console.error(error);
  },
});
```

## Development

> **NOTE:** You must have Docker installed to run the local Hasura instance.

### Setup

1. Install dependencies:

   ```bash
   pnpm install
   ```

2. Set up the Hasura backend:
   ```bash
   pnpm run dev
   # or from the root of the monorepo
   pnpm run dev:gql
   ```

### Making Changes

First, create a new issue on Linear and open a new branch/Github pull request. Do the following:

1. After running `pnpm run dev`, launch the Hasura GUI at http://localhost:9695 if it doesn't automatically.
2. Make changes to the database in the Hasura GUI.

<img width="1840" alt="image" src="https://github.com/user-attachments/assets/4ba39cfa-6717-48fe-91bf-9cda9882efbe">

3. A new `up.sql` file will be created in a new folder in `packages/migrations/default`. Check that the changes are valid. In some cases, you may need to write the `down.sql` file as well as hasura may not be able to automatically generate it.

<img width="1629" alt="image" src="https://github.com/user-attachments/assets/8769d3de-2038-41e0-9166-d38794279dd9">

> **NOTE:** After making changes you find that you have a lot of migrations. We can squash them down to a single migration if needed:
>
> ```bash
> # squash all migrations from version 123 to the latest one:
> hasura migrate squash --name "some_name" --from 123
> ```

5. Commit the changes and open a pull request.

### Testing

Run the test suite:

```bash
pnpm test
```

For watch mode:

```bash
pnpm test:watch
```

For coverage:

```bash
pnpm test:coverage
```

### Working with Hasura

Hasura migrations and metadata are two key components that work together to manage your Hasura project's state and schema. The local console, accessed through the Hasura CLI, provides a user-friendly interface to interact with these components. Here's how they work together:

1. **Local Console**:
   The local console is launched using the `pnpm hasura console` command. It provides a web interface to manage your Hasura project. When you make changes in the console. This is the preferred/simplest method to make changes:
   - Database schema changes trigger the creation of new migration files
   - Configuration changes update the metadata files
     > **MAKE SURE TO USE THE LOCAL CONSOLE LAUNCHED FROM THE CLI(http://locahost:9695) FOR SCHEMA AND METADATA CHANGES TO BE REFLECTED IN THE PROJECT FILES. BROWSER CONSOLE WILL NOT WORK AS THE FILES WONT BE UPDATED/GENERATED LOCALLY FOR YOU TO COMMIT.**
2. **Migrations**:
   Migrations are used to manage changes to your database schema over time. When you make changes to your database structure using the local console, Hasura automatically generates migration files. These files contain SQL statements that represent the changes made to your database schema.

   Manual commands for working with migrations include:

   - `pnpm hasura migrate create`: Creates a new migration file
   - `pnpm hasura migrate apply`: Applies pending migrations to the database
   - `pnpm hasura migrate status`: Shows the status of migrations

3. **Metadata**:
   Metadata represents the configuration of your Hasura instance, including table relationships, permissions, and custom actions. When you make changes in the console, such as creating relationships or setting up permissions, these changes are reflected in the metadata.

   Manual commands for managing metadata are:

   - `pnpm hasura metadata export`: Exports the current metadata
   - `pnpm hasura metadata apply`: Applies the metadata to the Hasura instance
   - `pnpm hasura metadata reload`: Reloads the metadata from the database

4. **Working in Tandem**:

   - When you run `pnpm hasura console`, it starts a local server that watches for changes made in the console.
   - As you make changes in the console, migration files and metadata files are automatically updated in your project directory.
   - You can then use version control to track these changes and collaborate with your team.
   - When deploying, you can use `pnpm hasura migrate apply` and `pnpm hasura metadata apply` to update your production instance.

5. **Consistency**:
   The `pnpm hasura metadata inconsistency` command helps you identify and resolve any inconsistencies between your metadata and the actual database schema.

For more detailed information on each command and its usage, you can refer to the [Hasura CLI Commands documentation](https://hasura.io/docs/2.0/hasura-cli/commands/index/).

## Deployment

Before making a database or GraphQL schema change to the production Hasura instance, add the following environment variables to the project root `.env` file.

```
HASURA_URL=https://tub-graphql.primodium.ai/
HASURA_ADMIN_SECRET=<Ask Emerson for the secret>
```

Once the pull request has been approved by another team member and merged into `main`, run the following command in `packages/tub` to apply changes to production:

1. Check the status of the migrations with the following command. Make sure that the migration is not already applied:

```
pnpm run hasura:remote:migrate-status
```

2. Apply the migrations and metadata to the production instance with the following commands:

```
pnpm run hasura:remote:apply-migrations
pnpm run hasura:remote:apply-metadata
```
