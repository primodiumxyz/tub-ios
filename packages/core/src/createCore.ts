import { AnchorProvider, Program, Wallet } from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";

import { Tub } from "@tub/contracts/target/types/tub";
import { Counter } from "@tub/contracts/target/types/counter";
import { TransferSol } from "@tub/contracts/target/types/transfer_sol";
import IDLTub from "@tub/contracts/target/idl/tub.json";
import IDLTransferSol from "@tub/contracts/target/idl/transfer_sol.json";
import IDLCounter from "@tub/contracts/target/idl/counter.json";

import { createUmi } from '@metaplex-foundation/umi-bundle-defaults'
import { mplTokenMetadata } from '@metaplex-foundation/mpl-token-metadata'
import { createCalls } from "./createCalls";

// Add this function to create an Anchor compatible wallet

export const createPrograms = (provider: AnchorProvider) => {
  return {
    tub: new Program<Tub>(IDLTub as Tub, provider),
    counter: new Program<Counter>(IDLCounter as Counter, provider),
    transferSol: new Program<TransferSol>(
      IDLTransferSol as TransferSol,
      provider
    ),
  };
};

export const createCore = (
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

  const provider = new AnchorProvider(
    connection,
    wallet,
    AnchorProvider.defaultOptions()
  );



  const programs = createPrograms(provider);
  
  // =============================================================================
  // PDA of Tub, the default counter program

  const [transferSolPDA] = PublicKey.findProgramAddressSync(
    [Buffer.from("transfer_sol")],
    programs.transferSol.programId
  );

  const [counterPDA] = PublicKey.findProgramAddressSync(
    [Buffer.from("randomSeed")],
    programs.counter.programId
  );

  const calls = createCalls(wallet, connection, programs);

  const core = {
    umi,
    constants: {
      SOLANA_LOCALNET,
      ADDRESS_TOKEN_PROGRAM,
      ADDRESS_TOKEN_METADATA_PROGRAM,
    },
    programs,
    pdas: {
      counter: counterPDA,
      transferSol: transferSolPDA,
    },
    calls,
  };

  return core;
};
