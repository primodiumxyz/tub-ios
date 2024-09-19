import { IdlAccounts } from "@coral-xyz/anchor";
import { Counter } from "@tub/contracts/target/types/counter";
import { createCore, createPrograms } from "./createCore";

export type Core = ReturnType<typeof createCore>;

export type CounterData = IdlAccounts<Counter>["counter"];

export enum ProgramId {
  TUB = "tub",
  COUNTER = "counter",
  TRANSFER_SOL = "transferSol",
}
export type Programs = ReturnType<typeof createPrograms>;