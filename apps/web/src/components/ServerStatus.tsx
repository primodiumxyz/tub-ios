import { useEffect, useState } from "react";
import { useServer } from "../hooks/useServer";

export default function ServerStatus() {
  const server = useServer();
  const [status, setStatus] = useState<number | undefined>(undefined);

  useEffect(() => {
    (async () => {
      try {
        const status = await server?.getStatus.query();
        setStatus(status?.status ?? 404);
      } catch (e) {
        console.log({ e });
        setStatus(404);
      }
    })();
  }, [server]);

  return (
    <div className="absolute top-2 left-2 shadow-md flex flex-row justify-center gap-10 items-center bg-slate-300 rounded-xl p-2">
      <p className="text-md">Server Status</p>
      <p
        className={`text-md ${
          status === undefined ? "bg-slate-400" : status === 200 ? "bg-green-400" : "bg-red-400"
        } rounded-md p-2`}
      >
        {status}
      </p>
    </div>
  );
}
