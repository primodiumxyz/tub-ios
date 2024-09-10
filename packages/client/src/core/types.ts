import { IdlAccounts, Program } from "@coral-xyz/anchor";
import { Tub } from "../../../contracts/target/types/tub";
import { CreateToken } from "../../../contracts/target/types/create_token";
import { PublicKey } from "@solana/web3.js";

export type Core = {
  constants: {
    SOLANA_LOCALNET: boolean;
    ADDRESS_TOKEN_PROGRAM: string;
    ADDRESS_TOKEN_METADATA_PROGRAM: string;
    ADDRESS_TOKEN_MINT_ACCOUNT: string;
  };
  programs: {
    tub: Program<Tub>;
    createToken: Program<CreateToken>;
  };
  pdas: Record<ProgramId, PublicKey>;
};

export type CounterData = IdlAccounts<Tub>["counter"];
export type CreateMintData = IdlAccounts<CreateToken>["asdf"];

export enum ProgramId {
  TUB = "tub",
  CREATE_TOKEN = "createToken",
}