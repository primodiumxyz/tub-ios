import { Core, CounterData } from "@tub/core";

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
}
