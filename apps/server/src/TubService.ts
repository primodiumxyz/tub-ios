import { parseEnv } from "../bin/parseEnv";
import { Core, CounterData } from "@tub/core";
import { GqlClient } from "@tub/gql";
import { config } from "dotenv";
import jwt from "jsonwebtoken";

config({ path: "../../.env" });

type CounterUpdateCallback = (value: number) => void;

const env = parseEnv();

export class TubService {
  private core: Core;
  private counterSubscribers: Set<CounterUpdateCallback> = new Set();
  private counter: number = 0;
  private gql: GqlClient["db"];

  constructor(core: Core, gqlClient: GqlClient["db"]) {
    this.core = core;
    this.gql = gqlClient;

    this.initializeCounterSubscription();
  }

  private verifyJWT = (token: string) => {
    try {
      const payload = jwt.verify(token, env.PRIVATE_KEY) as jwt.JwtPayload;
      return payload.uuid;
    } catch (e: any) {
      throw new Error(`Invalid JWT: ${e.message}`);
    }
  };

  getStatus(): { status: number } {
    return { status: 200 };
  }

  async incrementCall(): Promise<void> {
    await this.core.calls.increment();
  }

  private async initializeCounterSubscription() {
    const counterProgram = this.core.programs.counter;
    const connection = this.core.connection;
    const pdas = this.core.pdas;

    //get initial counter value
    const counter = await counterProgram.account.counter.fetch(pdas.counter);
    this.counter = counter.count.toNumber() ?? 0;

    connection.onAccountChange(pdas.counter, (accountInfo) => {
      const counter: CounterData = counterProgram.coder.accounts.decode("counter", accountInfo.data);
      this.counter = counter.count.toNumber() ?? 0;
      this.notifySubscribers(counter.count.toNumber() ?? 0);
    });
  }

  private notifySubscribers(value: number) {
    for (const subscriber of this.counterSubscribers) {
      subscriber(value);
    }
  }

  subscribeToCounter(callback: CounterUpdateCallback) {
    // send the current counter value to the subscriber
    callback(this.counter);

    this.counterSubscribers.add(callback);
  }

  unsubscribeFromCounter(callback: CounterUpdateCallback) {
    this.counterSubscribers.delete(callback);
  }

  async registerNewUser(username: string, airdropAmount: bigint) {
    const result = await this.gql.RegisterNewUserMutation({
      username: username,
      amount: airdropAmount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    const uuid = result.data?.insert_account_one?.id;

    if (!uuid) {
      throw new Error("Failed to register new user");
    }

    const token = jwt.sign({ uuid }, env.PRIVATE_KEY, { expiresIn: "5y" });

    return { uuid, token };
  }

  async refreshToken(uuid: string) {
    const token = jwt.sign({ uuid }, env.PRIVATE_KEY, { expiresIn: "5y" });
    return token;
  }

  async sellToken(token: string, tokenId: string, amount: bigint) {
    const accountId = this.verifyJWT(token);

    const result = await this.gql.SellTokenMutation({
      account: accountId,
      token: tokenId,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(token: string, tokenId: string, amount: bigint) {
    const accountId = this.verifyJWT(token);

    const result = await this.gql.BuyTokenMutation({
      account: accountId,
      token: tokenId,
      amount: amount.toString(),
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
    const accountId = this.verifyJWT(token);

    const result = await this.gql.AirdropNativeToUserMutation({
      account: accountId,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }
}
