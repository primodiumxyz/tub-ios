import { useEffect, useState } from "react";
import { useConnection } from "@solana/wallet-adapter-react";
import { CounterData } from "../core/types";
import { useCore } from "../hooks/useCore";

export default function CounterState() {
  const [counterData, setCounterData] = useState<CounterData | null>(null);
  const { programs, tubPDA } = useCore();
  const { connection } = useConnection();
  const tubProgram = programs.tub;

  useEffect(() => {
    tubProgram.account.counter.fetch(tubPDA).then((data) => {
      setCounterData(data);
    });

    const subscriptionId = connection.onAccountChange(tubPDA, (accountInfo) => {
      setCounterData(
        tubProgram.coder.accounts.decode("counter", accountInfo.data)
      );
    });

    return () => {
      connection.removeAccountChangeListener(subscriptionId);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tubProgram]);

  return <p>Count: {counterData?.count?.toString()}</p>;
}
