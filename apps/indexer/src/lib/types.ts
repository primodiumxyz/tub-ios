import { Idl } from "@coral-xyz/anchor";
import { ParsedInstruction } from "@shyft-to/solana-transaction-parser";
import { PublicKey, TransactionInstruction } from "@solana/web3.js";

/* ------------------------------- PARSED DATA ------------------------------ */
export type Swap = {
  vaultA: PublicKey;
  vaultB: PublicKey;
  transferInfo: TransferInformation[];
  timestamp: number;
};

export type SwapWithPriceAndMetadata = Omit<Swap, "transferInfo"> &
  SwapTokenPrice & {
    metadata: SwapTokenMetadata;
  };

type TransferInformation = {
  accounts: PublicKey[];
  amount: bigint;
};

type SwapTokenPrice = {
  mint: PublicKey;
  priceUsd: number;
  amount: bigint;
  tokenDecimals: number;
};

export type SwapTokenMetadata = {
  name: string;
  symbol: string;
  description: string;
  imageUri?: string;
  externalUrl?: string;
  supply?: number;
  isPumpToken: boolean;
};

/* --------------------------------- PARSERS -------------------------------- */
export type TransactionWithParsed = {
  raw: TransactionInstruction;
  // @ts-expect-error: type difference @coral-xyz/anchor -> @project-serum/anchor
  parsed: ParsedInstruction<Idl, string>;
};

/* ----------------------------------- RPC ---------------------------------- */
export type ParsedTokenBalanceInfo = {
  isNative: boolean;
  mint: string;
  owner: string;
  state: string;
  tokenAmount: {
    amount: string;
    decimals: number;
    uiAmount?: number;
    uiAmountString?: string;
  };
};

export type GetJupiterPriceResponse = {
  data: { [id: string]: { price: number } };
};

export type GetAssetsResponse = {
  result: {
    interface:
      | "V1_NFT"
      | "V1_PRINT"
      | "LEGACY_NFT"
      | "V2_NFT"
      | "FungibleAsset"
      | "Custom"
      | "Identity"
      | "Executable"
      | "ProgrammableNFT";
    id: string;
    content: {
      $schema: string;
      json_uri: string;
      files: Array<{
        uri: string;
        mime: string;
        quality?: Record<string, unknown>;
        contexts?: string[];
      }>;
      metadata: {
        name: string;
        description: string;
        symbol: string;
        token_standard: string;
        attributes: Array<{
          value: string | number;
          trait_type: string;
        }>;
      };
      links?: {
        external_url?: string;
        image?: string;
      };
    };
    authorities: Array<{
      address: string;
      scopes: Array<"full" | "royalty" | "metadata" | "extension">;
    }>;
    compression?: {
      asset_hash: string;
      compressed: boolean;
      creator_hash: string;
      data_hash: string;
      eligible: boolean;
      leaf_id: number;
      seq: number;
      tree: string;
    };
    grouping: Array<{
      group_key: "collection";
      group_value: string;
    }>;
    royalty: {
      basis_points: number;
      locked: boolean;
      percent: number;
      primary_sale_happened: boolean;
      royalty_model: "creators" | "fanout" | "single";
      target: string;
    };
    creators: Array<{
      address: string;
      share: number;
      verified: boolean;
    }>;
    ownership: {
      delegate: string;
      delegated: boolean;
      frozen: boolean;
      owner: string;
      ownership_model: "single" | "token";
    };
    uses?: {
      remaining: number;
      total: number;
      use_method: "burn" | "multiple" | "single";
    };
    supply?: {
      edition_nonce: number;
      print_current_supply: number;
      print_max_supply: number;
    };
    mutable: boolean;
    burnt: boolean;
  }[];
};
