import { Codex } from "@codex-data/sdk";
import { PrivyClient, WalletWithMetadata } from "@privy-io/server-auth";
import { Connection, Keypair, PublicKey, Transaction } from "@solana/web3.js";
import { GqlClient } from "@tub/gql";
import bs58 from "bs58";
import { config } from "dotenv";

import { env } from "@bin/tub-server";
import { createTransferInstruction, getAssociatedTokenAddressSync } from "@solana/spl-token";

config({ path: "../../.env" });

export class TubService {
  private gql: GqlClient["db"];
  private privy: PrivyClient;
  private codexSdk: Codex;
  private connection: Connection;

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient, codexSdk: Codex) {
    this.gql = gqlClient;
    this.privy = privy;
    this.codexSdk = codexSdk;
    this.connection = new Connection(env.QUICKNODE_MAINNET_URL);
  }

  private verifyJWT = async (token: string) => {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      return verifiedClaims.userId;
    } catch (e: unknown) {
      throw new Error(`Invalid JWT: ${e instanceof Error ? e.message : "Unknown error"}`);
    }
  };

  private async getUserWallet(userId: string) {
    const user = await this.privy.getUserById(userId);

    const solanaWallet = user.linkedAccounts.find(
      (account) => account.type === "wallet" && account.chainType === "solana",
    ) as WalletWithMetadata | undefined;
    return solanaWallet?.address;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async sellToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.SellTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(jwtToken: string, tokenId: string, amount: bigint, tokenPrice: number) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.BuyTokenMutation({
      wallet,
      token: tokenId,
      amount: amount.toString(),
      token_price: tokenPrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }
    return result.data;
  }

  async airdropNativeToUser(jwtToken: string, amount: bigint) {
    const accountId = await this.verifyJWT(jwtToken);
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }
    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async getSignedTransfer(
    jwtToken: string,
    args: { fromAddress: string; toAddress: string; amount: bigint; tokenId: string },
  ): Promise<{ transactionBase64: string; signatureBase64: string; signerBase58: string }> {
    const accountId = await this.verifyJWT(jwtToken);
    const keypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));
    const wallet = await this.getUserWallet(accountId);
    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const tokenMint = new PublicKey(args.tokenId);

    const fromPublicKey = new PublicKey(args.fromAddress);
    const toPublicKey = new PublicKey(args.toAddress);

    const fromTokenAccount = getAssociatedTokenAddressSync(tokenMint, fromPublicKey);
    const toTokenAccount = getAssociatedTokenAddressSync(tokenMint, toPublicKey);

    const transferInstruction = createTransferInstruction(fromTokenAccount, toTokenAccount, fromPublicKey, args.amount);

    const transaction = new Transaction();

    const blockhash = await this.connection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash.blockhash;

    transaction.sign(keypair);
    if (transaction.signatures.length === 0) {
      throw new Error("Transaction is not signed");
    }
    const sigData = transaction.signatures[0];
    if (!sigData) {
      throw new Error("Transaction is not signed");
    }
    const { signature: rawSignature, publicKey } = sigData;

    if (!rawSignature) {
      throw new Error("Transaction is not signed");
    }
    transaction.feePayer = keypair.publicKey;

    transaction.add(transferInstruction);

    console.log("transaction", transaction);
    const transactionBase64 = transaction.serialize({ requireAllSignatures: false }).toString("base64");
    const signature = Buffer.from(rawSignature).toString("base64");

    return { transactionBase64, signatureBase64: signature, signerBase58: publicKey.toBase58() };
  }

  async recordClientEvent(
    event: {
      userAgent: string;
      eventName: string;
      metadata?: string;
      errorDetails?: string;
      source?: string;
      buildVersion?: string;
    },
    token: string,
  ) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.AddClientEventMutation({
      user_agent: event.userAgent,
      event_name: event.eventName,
      metadata: event.metadata,
      user_wallet: wallet,
      error_details: event.errorDetails,
      source: event.source,
      build: event.buildVersion,
    });

    const id = result.data?.insert_analytics_client_event_one?.id;

    if (!id) {
      throw new Error("Failed to record client event. Missing ID.");
    }

    if (result.error) {
      throw new Error(result.error.message);
    }

    return id;
  }

  async requestCodexToken(expiration?: number) {
    expiration = expiration ?? 3600 * 1000;
    try {
      const res = await this.codexSdk.mutations.createApiTokens({
        input: { expiresIn: expiration },
      });

      const token = res.createApiTokens[0]?.token;
      const expiry = res.createApiTokens[0]?.expiresTimeString;
      if (!token || !expiry) {
        throw new Error("Failed to create Codex API token");
      }
      return { token: `Bearer ${token}`, expiry };
    } catch (error) {
      console.log(` error: ${error}`);
      throw error;
    }
  }
}
