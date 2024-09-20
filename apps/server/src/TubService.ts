import { Core } from "@tub/core";

type CounterUpdateCallback = (value: number) => void;

export class TubService {
  private core: Core;
  private counterSubscribers: Set<CounterUpdateCallback> = new Set();

  constructor(core: Core) {
    this.core = core;
    this.initializeCounterSubscription();
  }

  getStatus(): { status: number } {
    return { status: 200 };
  }

  incrementCall(): void {
    this.core.calls.increment();
  }

  private initializeCounterSubscription() {
    const counterProgram = this.core.programs.counter;
    const connection = this.core.connection;
    const pdas = this.core.pdas;

    connection.onAccountChange(pdas.counter, (accountInfo) => {
      const counter = counterProgram.coder.accounts.decode("counter", accountInfo.data);
      this.notifySubscribers(counter.count);
    });
  }

  private notifySubscribers(value: number) {
    for (const subscriber of this.counterSubscribers) {
      subscriber(value);
    }
  }

  subscribeToCounter(callback: CounterUpdateCallback) {
    this.counterSubscribers.add(callback);
  }

  unsubscribeFromCounter(callback: CounterUpdateCallback) {
    this.counterSubscribers.delete(callback);
  }
}
