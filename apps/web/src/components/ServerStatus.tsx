import { useEffect, useState } from "react";
import { useServer } from "../hooks/useServer";

export default function IncrementForm() {
  const { ready, server } = useServer();
  const [status, setStatus] = useState<number>();

  useEffect(() => {
    if (!ready) return;

    (async () => {
      const status = await server?.getStatus.query();
      setStatus(status?.status ?? 404);
    })();
  }, [server, ready]);

  return (
    <div className="absolute top-2 left-2 shadow-md flex flex-row justify-center gap-10 items-center bg-slate-300 rounded-xl p-2">
      <p className="text-md">Server Status</p>
      <p className="text-md bg-slate-400 rounded-md p-2">{status}</p>
    </div>
  );
}
