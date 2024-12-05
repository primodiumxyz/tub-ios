import React, { createContext, useMemo } from "react";

import { createClient as createServerClient } from "@tub/server";

export type ServerContextType = ReturnType<typeof createServerClient>;

export const ServerContext = createContext<ServerContextType | null>(null);

const dev = import.meta.env.VITE_USER_NODE_ENV !== "production";
const httpUrl = dev ? "http://localhost:8888/trpc" : "https://tub-server.primodium.ai/trpc";
const wsUrl = dev ? "ws://localhost:8888/trpc" : "wss://tub-server.primodium.ai/trpc";

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
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

  return <ServerContext.Provider value={server}>{children}</ServerContext.Provider>;
};
