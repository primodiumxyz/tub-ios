import { useEffect, useState } from "react";
import { useServer } from "../hooks/useServer";

export default function CounterState() {
  const [counter, setCounter] = useState<number | null>(null);
  const server = useServer();

  useEffect(() => {
    const unsub = server.onCounterUpdate.subscribe(undefined, {
      onData: (data) => {
        setCounter(data);
      },
    });

    return () => {
      unsub.unsubscribe();
    };
  }, [server]);

  return <p>Count: {counter}</p>;
}
