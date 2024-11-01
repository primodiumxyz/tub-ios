import React, { createContext, useMemo } from "react";

import { createClient as createServerClient } from "@tub/server";

export type ServerContextType = ReturnType<typeof createServerClient>;

export const ServerContext = createContext<ServerContextType | null>(null);

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const server = useMemo(() => {
    return createServerClient({
      httpUrl: "http://localhost:8888/trpc",
      wsUrl: "ws://localhost:8888/trpc",
      httpHeaders: () => {
        return {
          Authorization: `Bearer xxx`,
        };
      },
    });
  }, []);

  return <ServerContext.Provider value={server}>{children}</ServerContext.Provider>;
};
