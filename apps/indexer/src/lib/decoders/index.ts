import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { VersionedTransactionResponse } from "@solana/web3.js";

import {
  METEORA_DLMM_PUBLIC_KEY,
  ORCA_WHIRLPOOL_PUBLIC_KEY,
  RAYDIUM_AMM_PUBLIC_KEY,
  RAYDIUM_CLAMM_PUBLIC_KEY,
} from "@/lib/constants";
import { decodeMeteoraDLMMTx } from "@/lib/decoders/meteora-dlmm";
import { decodeOrcaWhirlpoolTx } from "@/lib/decoders/orca-whirlpool";
import { decodeRaydiumAMMTx } from "@/lib/decoders/raydium-amm";
import { decodeRaydiumCLAMMTx } from "@/lib/decoders/raydium-clamm";
import { SwapAccounts } from "@/lib/types";

const decoders = {
  [METEORA_DLMM_PUBLIC_KEY.toString()]: decodeMeteoraDLMMTx,
  [ORCA_WHIRLPOOL_PUBLIC_KEY.toString()]: decodeOrcaWhirlpoolTx,
  [RAYDIUM_AMM_PUBLIC_KEY.toString()]: decodeRaydiumAMMTx,
  [RAYDIUM_CLAMM_PUBLIC_KEY.toString()]: decodeRaydiumCLAMMTx,
};

export const decodeSwapAccounts = (
  tx: VersionedTransactionResponse,
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsedIxs: ParsedInstruction<Idl, string>[],
): SwapAccounts[] => {
  // Filter out the instructions that are not related to the exchanges
  const programIxs = parsedIxs.filter((ix) => ix.programId.toString() in decoders);
  if (programIxs.length === 0) return [];

  // For each available decoder, decode the swap accounts if there is a swap instruction for its exchange
  // We could very well have multiple swaps across different exchanges in a single transaction
  // e.g. https://solscan.io/tx/2PDA4u11zqs69fUtJYkTYkWxuRkscQMPj2dVzvNbsD8QUtRFxALvxKnut71aBv6EYGC4zNEsEyNMizma7eQo12BT
  // USDC -> JLP (Orca) - JLP -> WSOL (Meteora) - WSOL -> BOME (Raydium)
  return Object.entries(decoders)
    .map(([programId, decoder]) => {
      if (programIxs.some((ix) => ix.programId.toString() === programId)) {
        return decoder(programIxs);
      }
      return [];
    })
    .flat();
};
