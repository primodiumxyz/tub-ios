import { AnchorProvider, Program } from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";

import { Tub } from "@tub/contracts/target/types/tub";
import { CreateToken } from "@tub/contracts/target/types/create_token";

import IDLTub from "@tub/contracts/target/idl/tub.json";
import IDLCreateToken from "@tub/contracts/target/idl/create_token.json";

import { Wallet } from "@solana/wallet-adapter-react";
import { SignerWalletAdapter } from "@solana/wallet-adapter-base";
import { createUmi } from '@metaplex-foundation/umi-bundle-defaults'
import { mplTokenMetadata } from '@metaplex-foundation/mpl-token-metadata'

// Add this function to create an Anchor compatible wallet

export const createCore = (
  publicKey: PublicKey,
  wallet: Wallet,
  connection: Connection
) => {
  // =============================================================================
  // future environment variables
  const SOLANA_LOCALNET = false;

  // SPL token program deployed on-chain
  const ADDRESS_TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";

  // token metadata program deployed on-chain
  const ADDRESS_TOKEN_METADATA_PROGRAM =
    "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s";

// Use the RPC endpoint of your choice.
const umi = createUmi(connection.rpcEndpoint).use(mplTokenMetadata())

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

   return {
    umi,
    constants: {
      SOLANA_LOCALNET,
      ADDRESS_TOKEN_PROGRAM,
      ADDRESS_TOKEN_METADATA_PROGRAM,
    },
    programs,
    pdas: {
      tub: tubPDA,
    },
  };
};
