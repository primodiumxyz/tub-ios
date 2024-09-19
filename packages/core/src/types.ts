import { IdlAccounts } from "@coral-xyz/anchor";
import { Counter } from "@tub/contracts/target/types/counter";
import { createCore } from "./createCore";

export type Core = ReturnType<typeof createCore>;

export type CounterData = IdlAccounts<Counter>["counter"];

export enum ProgramId {
  TUB = "tub",
  COUNTER = "counter",
  TRANSFER_SOL = "transferSol",
}
