# Tub Web Client

The `/apps/web` repository contains the TypeScript reference web client for Tub. It is used for developing the Solana programs located in `/packages/contracts`.

The web client was used for developing the Tub server, located in `/apps/server`, before the Swift iOS client was ready for GraphQL calls and deployment. Refer to the Swift iOS client at `/apps/ios` for the latest features and server integrations.

## Development

The web client is dependent on the Solana programs to run properly. Refer to the `Deploy` section of [`/packages/contracts/README.md`](/packages/contracts/README.md#Deploy) to deploy the Solana programs locally first, then run the following to run the web client.

```bash
pnpm run dev # Run the web client
```
