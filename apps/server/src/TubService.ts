import { Core, CounterData } from "@tub/core";
import { db } from "@tub/gql";

type CounterUpdateCallback = (value: number) => void;

export class TubService {
  private core: Core;
  private counterSubscribers: Set<CounterUpdateCallback> = new Set();
  private counter: number = 0;

  constructor(core: Core) {
    this.core = core;
    this.initializeCounterSubscription();
  }

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
    const result = await db.RegisterNewUserMutation({
      username: username,
      amount: airdropAmount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async sellToken(accountId: string, tokenId: string, amount: bigint) {
    const result = await db.SellTokenMutation({
      account: accountId,
      token: tokenId,
      amount: amount.toString(),
    });

    if (result.error) {
      throw new Error(result.error.message);
    }

    return result.data;
  }

  async buyToken(accountId: string, tokenId: string, amount: bigint) {
    const result = await db.BuyTokenMutation({
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
    const result = await db.RegisterNewTokenMutation({
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
}
