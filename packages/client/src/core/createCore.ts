import { AnchorProvider, Program } from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";

import { Tub } from "../../../contracts/target/types/tub";
import { CreateToken } from "../../../contracts/target/types/create_token";

import IDLTub from "../../../contracts/target/idl/tub.json";
import IDLCreateToken from "../../../contracts/target/idl/create_token.json";

import { Keypair } from "@solana/web3.js";
import { Core } from "./types";
import { Wallet } from "@solana/wallet-adapter-react";
import { SignerWalletAdapter } from "@solana/wallet-adapter-base";
// Add this function to create an Anchor compatible wallet

export const createCore = (
  publicKey: PublicKey,
  wallet: Wallet,
  connection: Connection
): Core => {
  // =============================================================================
  // future environment variables
  const SOLANA_LOCALNET = false;

  // SPL token program deployed on-chain
  const ADDRESS_TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";

  // token metadata program deployed on-chain
  const ADDRESS_TOKEN_METADATA_PROGRAM =
    "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s";
  const tokenMetadataProgramKey = new PublicKey(ADDRESS_TOKEN_METADATA_PROGRAM);

  // Generate new keypair for minting tokens
  const tokenMintAccount = new Keypair();
  const ADDRESS_TOKEN_MINT_ACCOUNT = tokenMintAccount.publicKey.toString();

  // =============================================================================

  const walletAdapter = {
    ...(wallet.adapter as SignerWalletAdapter),
    publicKey,
  };
  const provider = new AnchorProvider(
    connection,
    walletAdapter,
    AnchorProvider.defaultOptions()
  );
  wallet.adapter.sendTransaction;

  const programs = {
    tub: new Program<Tub>(IDLTub as Tub, provider),
    createToken: new Program<CreateToken>(
      IDLCreateToken as CreateToken,
      provider
    ),
  };

  // =============================================================================
  // PDA of Tub, the default counter program
  // seeds = [b"randomSeed"], // optional seeds for pda
  const [tubPDA] = PublicKey.findProgramAddressSync(
    [Buffer.from("randomSeed")],
    programs.tub.programId
  );

  // PDA of CreateToken, the program that creates new tokens
  // seeds = [b"metadata", token_metadata_program.key().as_ref(), mint_account.key().as_ref()],
  const [createTokenPDA] = PublicKey.findProgramAddressSync(
    [
      Buffer.from("metadata"),
      tokenMetadataProgramKey.toBuffer(),
      tokenMintAccount.publicKey.toBuffer(),
    ],
    tokenMetadataProgramKey
  );

  return {
    constants: {
      SOLANA_LOCALNET,
      ADDRESS_TOKEN_PROGRAM,
      ADDRESS_TOKEN_METADATA_PROGRAM,
      ADDRESS_TOKEN_MINT_ACCOUNT,
    },
    programs,
    pdas: {
      tub: tubPDA,
      createToken: createTokenPDA,
    },
  };
};
