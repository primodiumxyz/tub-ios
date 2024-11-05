import crypto from "crypto";
import { PrivyClient } from "@privy-io/server-auth";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";
import jwt from "jsonwebtoken";
import { parseEnv } from "../bin/parseEnv";

config({ path: "../../.env" });

const env = parseEnv();

export class TubService {
  private privy: PrivyClient;
  private gql: GqlClient["db"];

  constructor(gqlClient: GqlClient["db"], privy: PrivyClient) {
    this.gql = gqlClient;
    this.privy = privy;
  }

  private verifyJWT = async (token: string) => {
    try {
      const verifiedClaims = await this.privy.verifyAuthToken(token);
      return verifiedClaims.userId;
    } catch (e: any) {
      throw new Error(`Invalid JWT: ${e.message}`);
    }
  };

  private async getUserWallet(userId: string) {
    const user = await this.privy.getUserById(userId);
    return user.wallet?.address;
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async sellToken(token: string, tokenId: string, amount: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.SellTokenMutation({
      wallet: wallet,
      token: tokenId,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(token: string, tokenId: string, amount: bigint, overridePrice: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.BuyTokenMutation({
      wallet: wallet,
      token: tokenId,
      amount: amount.toString(),
      override_token_price: overridePrice.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async registerNewToken(name: string, symbol: string, supply: bigint = 100n, uri?: string) {
    const result = await this.gql.RegisterNewTokenMutation({
      name: name,
      symbol: symbol,
      supply: supply.toString(),
      uri: uri,
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async airdropNativeToUser(token: string, amount: bigint) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    if (!wallet) {
      throw new Error("User does not have a wallet");
    }

    const result = await this.gql.AirdropNativeToWalletMutation({
      wallet: wallet,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  // Coinbase CDP services, generates a secure onboarding URL based on the user's wallet
  async getCoinbaseSolanaOnrampUrl(token: string) {
    const accountId = await this.verifyJWT(token);
    const wallet = await this.getUserWallet(accountId);

    // Both strings are escaped by the CDP JSON generated by coinbase. Parsing is needed in code before using.
    const keyName = env.COINBASE_CDP_API_KEY_NAME.replace(/\\n/g, "\n");
    const keySecret = env.COINBASE_CDP_API_KEY_PRIVATE_KEY.replace(/\\n/g, "\n");

    if (!keyName || !keySecret) {
      return { status: 500 };
    }

    // Create a request for a JWT from Coinbase Developer
    const host = "api.developer.coinbase.com";
    const request_method = "POST";
    const requestPath = "/onramp/v1/token";

    const url = `https://${host}${requestPath}`;
    const uri = `${request_method} ${host}${requestPath}`;

    const payload = {
      iss: "coinbase-cloud",
      nbf: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 120,
      sub: keyName,
      uri,
    };

    const coinbaseSignOptions: jwt.SignOptions = {
      algorithm: "ES256",
      header: {
        kid: keyName,
        // @ts-ignore
        nonce: crypto.randomBytes(16).toString("hex"), // non-standard, coinbase-specific header, from onramp demo
      },
    };

    const coinbaseJwtToken = jwt.sign(payload, keySecret, coinbaseSignOptions);
    const body = {
      destination_wallets: [
        {
          address: wallet,
          blockchains: ["solana"],
        },
      ],
    };

    // Fetch from coinbase servers
    try {
      const coinbaseResponse = await fetch(url, {
        method: request_method,
        body: JSON.stringify(body),
        headers: { Authorization: "Bearer " + coinbaseJwtToken },
      });

      // Expected format from coinbase:
      // {
      //   token: 'MWVmOWFmNDQtNjgyYi02NTUyLTg3ZmEtNjI1NjMxYWRjYjUw',
      //   channel_id: ''
      // }
      const json = await coinbaseResponse.json();

      if (json.message) {
        return { status: 500, error: json.message };
      } else {
        return {
          token: json.token,
          url: `https://pay.coinbase.com/landing?sessionToken=${json.token}`,
        };
      }
    } catch (error) {
      return { status: 500, error: "Coinbase Onramp API returned an error." };
    }
  }
}
