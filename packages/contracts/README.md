# Tub

The project is structured as a `pnpm` monorepo with the following packages:

```yaml
- packages
    - contracts # Solana Rust programs implemented in anchor
    - core # TypeScript core logic and types for interacting with the Solana programs
    - gql # GraphQL API for the web client
- apps
    - keeper # TypeScript service for updating the database with random token data
    - web # TypeScript client for web
    - server # Node.js server for fetching state with various clients
    - indexer # Node.js server for listening to DEX trades and writing new tokens prices to the database
    - explorer # Temporary React app for browsing pumping tokens and playing with filters
```

### Links

- Rust Book: https://doc.rust-lang.org/book/
- Solana quickstart (for chain concepts): https://solana.com/docs/intro/quick-start
- Anchor (for Rust API reference): https://www.anchor-lang.com/docs/high-level-overview

## Installation

### pnpm

This monorepo uses `pnpm` as its package manager. First, install `npm`, then install `pnpm`.

```
npm install -g pnpm
```

This repository is tested with `node` version `18.18.0`, `npm` version `9.8.1`, and `pnpm` version `8.10.5`.

### Solana

Rust is required for Solana smart contracts, known as "programs". Since rust is a dependency of Foundry, it should already be installed. Double-check with the following commands:

```
# rustc, the Rust compiler
rustc --version

# cargo, the Rust package manager
cargo --version
```

If not, install it with the following command:

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

Then, install the [Solana CLI](https://solana.com/developers/guides/getstarted/setup-local-development#3-install-the-solana-cli). This repository uses `v1.17.25`.

```
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
```

Restart the terminal and type `solana --version` to confirm the version.

### Anchor

The Solana programs in this repository are implemented in [Anchor](https://www.anchor-lang.com/), a framework for building Solana programs.

This repository is tested with `rust` version `1.79.0` and `Anchor` version `v0.30.1`.

```
rustup install 1.79.0
rustup default 1.79.0
```

Install Anchor:

```
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force

# Install with Anchor Version Manager
avm install latest
avm use latest
```

Double-check with `anchor --version`.

```
anchor --version
```

## Development

### Local Validator

To run the local test validator, equivalent to running a test Ethereum chain with `anvil` in Foundry, run the following command:

```
pnpm validator
```

Then, set the Solana CLI to use the localhost validator.

```
# Set as local environment
solana config set --url localhost

# Get the current configuration
solana config get
```

Create and configure the [local filesystem wallet](https://solana.com/developers/guides/getstarted/setup-local-development#6-create-a-file-system-wallet) below:

```
# By default, this creates a new wallet with the keypair stored in ~/.config/solana/id.json
solana-keygen new

# Set above wallet as default
solana config set -k ~/.config/solana/id.json

# Airdrop 2 Solana in the wallet
solana airdrop 2
```

### Build

Run the following commands in `/packages/contracts`.

First, build the program:

```
anchor build
```

Test the program with Anchor:

```
anchor test
```

Deploy the program to the local validator:

```
anchor deploy
```

## Deploy

Run the following to switch between the Localnet and devnet with the solana CLI. For now, we will switch to the `devnet`.

```bash
solana config set --url devnet # switch to devnet
solana config set --url localhost # switch to Localnet
```

Then, modify `/packages/contracts/Anchor.toml` to point to the `devnet`.

```toml
[provider]
# cluster = "Localnet" # uncomment for Localnet
cluster = "devnet" # uncomment for devnet
wallet = "~/.config/solana/id.json"
```

> [!NOTE]  
> The recommended network to test Solana programs in the client is the public `devnet`. Phantom Wallet does not work with the `Localnet` cluster.

Deploy the program to the devnet with `anchor test`. The deployed program ID is printed as `Program Id`.

```bash
emersonhsieh@MacBook-Pro-2024 contracts % anchor test
    Finished release [optimized] target(s) in 0.11s
    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.13s
     Running unittests src/lib.rs (/Users/emersonhsieh/solana/tub/packages/contracts/target/debug/deps/tub-cebdc48a6fa11c61)
Deploying cluster: https://api.devnet.solana.com
Upgrade authority: /Users/emersonhsieh/.config/solana/id.json
Deploying program "tub"...
Program path: /Users/emersonhsieh/solana/tub/packages/contracts/target/deploy/tub.so...
Program Id: **2a1T6Xhad5kf6VvdcebQfK6RzAxcHxiAhskRYKNzmTYw**

Deploy success

Found a 'test' script in the Anchor.toml. Running it as a test suite!

Running test suite: "/Users/emersonhsieh/solana/tub/packages/contracts/Anchor.toml"

yarn run v1.22.19
$ /Users/emersonhsieh/solana/tub/packages/contracts/node_modules/.bin/ts-mocha -p ./tsconfig.json -t 1000000 'tests/**/*.ts'


  counter
Transaction Signature: 5pihdscCZcmCeYpNTwoZ5XZyo41FLfzxPK6HLDhH783n7a8utNpfmPYrrgmd1PJbCjyou8dVvmYsQypzxsopNwR5
Count: 0
    ✔ Is initialized! (846ms)
Transaction Signature: eDZiP4jHkWdR5doEq5YuW5jRZQTdTHZ16RxF533irqjsfeNmzWX3c3EKXAX2ydkeSM7TdDpz2KzofDXjAdZ5A75
Count: 1
    ✔ Increment (705ms)


  2 passing (2s)

✨  Done in 2.76s.
```

> [!NOTE]
> The `anchor test` command works with both `devnet` and `Localnet`:
>
> - Run `anchor test` on `Localnet` if you are developing tests in `/packages/contracts/tests`, in order to not wait for remote deployment on every change.
> - Run `anchor test` on `devnet` if you are testing Solana programs with the client. This command deploys the programs to the `devnet`.

> [!IMPORTANT]
> If you have already run `anchor test` with the `devnet`, `anchor deploy` is not necessary for testing the client locally since our programs will have already been deployed.

## Deploying the Token Metadata Program locally

> [!WARNING]  
> The recommended network to test Solana programs in the client is the public `devnet`. The following is for reference only.

All token metadata is stored in the [token metadata program](https://developers.metaplex.com/token-metadata) by Metaplex. It is necessary to clone the token program and the token metadata program for the `tub` programs to run properly on the local `solana-test-validator` chain.

There are two program dependencies for `tub`:

- tokenProgram: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`
- tokenMetadataProgram: `metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s`

Do the following in the `dumps/` directory.

First, dump the two programs:

```
cd dumps
solana program dump -u m TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA token.so
solana program dump -u m metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s token_metadata.so
```

Emerson has already the commands ahead of time, so there are existing dumps. The above can be run for the latest dumps.

Make sure `solana-test-validator` is running. Deploy the program below:

```
solana program deploy ./token.so
solana program deploy ./token_metadata.so
```

Below is the expected output:

```
emersonhsieh@MacBook-Pro-2024 dumps % solana program deploy ./token.so
Program Id: 4L2cdGSkqWCksP8Ub7ELYqgBzkjb1EAMaX555WPVZZLv

emersonhsieh@MacBook-Pro-2024 dumps % solana program deploy ./token_metadata.so
Program Id: D5QCcb8YJuxukogHEbPTftqGBdTCQyKsqgmbp3dooaA
```

Update the `SOLANA_ADDRESS_TOKEN_PROGRAM` and `SOLANA_ADDRESS_TOKEN_METADATA_PROGRAM` environment variables with the above respective addresses.

### Building token metadata program manually [optional]

Alternatively, the token metadata program can be cloned by building locally from source in a separate directory outside of this repo.

```
git clone https://github.com/metaplex-foundation/mpl-token-metadata
cd mpl-token-metadata/programs/token-metadata/
```

Build the program:

```
cargo build-bpf
```

Deploy the program:

```
solana program deploy target/deploy/token_metadata.so
```

Below is the expected output:

```
Finished release [optimized] target(s) in 0.19s
emersonhsieh@MacBook-Pro-2024 token-metadata % solana program deploy target/deploy/token_metadata.so

Program Id: E4LBnNKM1LFpLbWXFQbjsi12BdjiCxjxkWikuALiCV7E
```

### Test with local token programs [optional]

Before the `[[test.validator.clone]]` section in '/packages/contracts/Anchor.toml' was added, testing the `create-token` contracts locally used to require the token metadata contracts to be deployed to the localnet. Below are instructions for using the deployed address above.

Update `Anchor.toml` with the `token_metadata_program` address in `/packages/contracts/Anchor.toml":

```toml
[programs.localnet]
tub = "2a1T6Xhad5kf6VvdcebQfK6RzAxcHxiAhskRYKNzmTYw"
create_token = "6aLsHmmAB7GNbQn6czDjBMwjre5gFi8NQmtMk3SireBE"
token_metadata_program = "new address here"
```

Head back to `/packages/contracts/Anchor.toml` and run the tests.

## Adding a new program

New Solana programs are added in `/packages/contracts/programs`. After creating a new program, copy the program public key from the `declare_id!` field in its `lib.rs`:

```rust
declare_id!("B8SshXZbFQK29wAfCKciWnYvnReaJjpjmehq5v5RxVpc");
```

and paste the address and the program name in `/packages/contracts/Anchor.toml` under the `[programs.devnet]` and [programs.devnet]` table headers.

```toml
[programs.devnet]
transfer_sol = "B8SshXZbFQK29wAfCKciWnYvnReaJjpjmehq5v5RxVpc" # in snake_case, see note below
new_program_name = "new address here" # new address here

[programs.localnet]
transfer_sol = "B8SshXZbFQK29wAfCKciWnYvnReaJjpjmehq5v5RxVpc" # in snake_case, see note below
new_program_name = "new address here" # new address here
```

> [!NOTE]  
> The key of each program referenced above is the program name listed in the `[lib]` table header of the program's individual `Cargo.toml`, which uses `camel_case` (`new_program_name`).
>
> For example, the `transfer-sol` program uses `kebab-case` for the program directory (`/packages/contracts/programs/transfer-sol`). However, `/packages/contracts/programs/transfer-sol/Cargo.toml` uses `transfer_sol` as the library name:
>
> ```toml
> [lib]
> crate-type = ["cdylib", "lib"]
> name = "transfer_sol"
> ```
>
> `transfer_sol` is therefore used to reference the program library in `/packages/contracts/Anchor.toml`.

## Running a full stack client

```bash
pnpm dev # this will spin up the keeper, server, and web app
```
