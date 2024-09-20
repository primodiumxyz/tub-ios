import { useEffect, useState } from "react";
import { useConnection } from "@solana/wallet-adapter-react";
import { useCore } from "../hooks/useCore";
import { CounterData } from "@tub/core";

export default function CounterState() {
  const [counterData, setCounterData] = useState<CounterData | null>(null);
  const { programs, pdas } = useCore();
  const { connection } = useConnection();
  const counterProgram = programs.counter;

  useEffect(() => {
    counterProgram.account.counter.fetch(pdas.counter).then((data) => {
      setCounterData(data);
    });

    const subscriptionId = connection.onAccountChange(pdas.counter, (accountInfo) => {
      setCounterData(
        counterProgram.coder.accounts.decode("counter", accountInfo.data)
      );
    });

    return () => {
      connection.removeAccountChangeListener(subscriptionId);
    };
  }, [connection, counterProgram, pdas.counter]);

  return <p>Count: {counterData?.count?.toString()}</p>;
}
