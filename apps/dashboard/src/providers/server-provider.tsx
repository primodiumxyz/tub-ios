import React, { createContext, useEffect, useMemo, useState } from "react";
import { Codex } from "@codex-data/sdk";

import { createClient as createServerClient } from "@tub/server";

export type ServerContextType = ReturnType<typeof createServerClient> & {
  codexSdk: Codex | undefined;
};

export const ServerContext = createContext<ServerContextType | null>(null);

const dev = import.meta.env.VITE_USER_NODE_ENV !== "production";
const httpUrl = dev ? "http://localhost:8888/trpc" : "https://tub-server.primodium.ai/trpc";
const wsUrl = dev ? "ws://localhost:8888/trpc" : "wss://tub-server.primodium.ai/trpc";

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [codexToken, setCodexToken] = useState<string | null>(null);

  const server = useMemo(() => {
    return createServerClient({
      httpUrl,
      wsUrl,
      httpHeaders: () => {
        return {
          Authorization: `Bearer xxx`,
        };
      },
    });
  }, []);

  const codexSdk = useMemo(() => {
    if (!codexToken) return;
    return new Codex(codexToken);
  }, [codexToken]);

  useEffect(() => {
    if (!codexToken) server.requestCodexToken.mutate({ expiration: 3600 * 1000 }).then(setCodexToken);
  }, [codexToken, server.requestCodexToken]);

  return <ServerContext.Provider value={{ ...server, codexSdk }}>{children}</ServerContext.Provider>;
};
