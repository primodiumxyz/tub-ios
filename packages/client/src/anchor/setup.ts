import { IdlAccounts, Program } from "@coral-xyz/anchor";
import { clusterApiUrl, Connection, PublicKey } from "@solana/web3.js";

import { Tub } from "../../../contracts/target/types/tub";
import { CreateToken } from "../../../contracts/target/types/create_token";

import IDLTub from "../../../contracts/target/idl/tub.json";
import IDLCreateToken from "../../../contracts/target/idl/create_token.json";

import { Keypair } from "@solana/web3.js";

// =============================================================================
// future environment variables
export const SOLANA_LOCALNET = false;

// const SOLANA_ADDRESS_TOKEN_PROGRAM =
//   "AA8x8caQsYX3iCHp93QJpMCvxzA4hM6WvXZuza1ruSbe";

// token metadata program deployed on-chain
export const ADDRESS_TOKEN_METADATA_PROGRAM =
  "Dt3H1H6JjjaL4V6A2UkKQ6ivvYQqN8wZrVk4vieVvDd7";
const tokenMetadataProgramKey = new PublicKey(ADDRESS_TOKEN_METADATA_PROGRAM);

// Generate new keypair for minting tokens
export const tokenMintAccount = new Keypair();
export const ADDRESS_TOKEN_MINT_ACCOUNT = tokenMintAccount.publicKey.toString();

// =============================================================================
// Programs
const connection = SOLANA_LOCALNET
  ? new Connection("http://localhost:8899/")
  : new Connection(clusterApiUrl("devnet"), "confirmed");

console.log(connection);

export const programs = {
  tub: new Program<Tub>(IDLTub as Tub, {
    connection,
  }),
  createToken: new Program<CreateToken>(IDLCreateToken as CreateToken, {
    connection,
  }),
};

// =============================================================================
// PDA of Tub, the default counter program
// seeds = [b"randomSeed"], // optional seeds for pda
export const [tubPDA] = PublicKey.findProgramAddressSync(
  [Buffer.from("randomSeed")],
  programs.tub.programId
);

// PDA of CreateToken, the program that creates new tokens
// seeds = [b"metadata", token_metadata_program.key().as_ref(), mint_account.key().as_ref()],
export const [createTokenPDA] = PublicKey.findProgramAddressSync(
  [
    Buffer.from("metadata"),
    tokenMetadataProgramKey.toBuffer(),
    tokenMintAccount.publicKey.toBuffer(),
  ],
  tokenMetadataProgramKey
);

export type CounterData = IdlAccounts<Tub>["counter"];
export type CreateMintData = IdlAccounts<CreateToken>["asdf"];
