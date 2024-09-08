import { IdlAccounts, Program } from "@coral-xyz/anchor";
import { Tub } from "../../../contracts/target/types/tub";
import IDL from "../../../contracts/target/idl/tub.json";
import { clusterApiUrl, Connection, PublicKey } from "@solana/web3.js";

// future environment variable
const SOLANA_LOCALNET = false;

const connection = SOLANA_LOCALNET
  ? new Connection("http://localhost:8899/")
  : new Connection(clusterApiUrl("devnet"), "confirmed");

export const program = new Program<Tub>(IDL as Tub, {
  connection,
});

export const [counterPDA] = PublicKey.findProgramAddressSync(
  [Buffer.from("randomSeed")],
  program.programId
);

export type CounterData = IdlAccounts<Tub>["counter"];
