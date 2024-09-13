import { IdlAccounts } from "@coral-xyz/anchor";
import { Tub } from "@tub/contracts/target/types/tub";
import { CreateToken } from "@tub/contracts/target/types/create_token";
import { createCore } from "./createCore";

export type Core = ReturnType<typeof createCore>

export type CounterData = IdlAccounts<Tub>["counter"];
export type CreateMintData = IdlAccounts<CreateToken>["asdf"];

export enum ProgramId {
  TUB = "tub",
  CREATE_TOKEN = "createToken",
}
