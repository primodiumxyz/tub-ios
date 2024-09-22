import { useEffect, useState } from "react";
import { useServer } from "../hooks/useServer";

export default function CounterState() {
  const [counter, setCounter] = useState<number | null>(null);
  const { server, ready } = useServer();

  useEffect(() => {
    if (!server || !ready) return;

    const unsub = server.onCounterUpdate.subscribe(undefined, {
      onData: (data) => {
        setCounter(data);
      },
    });

    return () => {
      unsub.unsubscribe();
    };
  }, [server, ready]);

  return <p>Count: {counter}</p>;
}
