import React, { createContext, useMemo } from "react";

import { createClient as createServerClient } from "@tub/server";

export type ServerContextType = ReturnType<typeof createServerClient>;

export const ServerContext = createContext<ServerContextType | null>(null);

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const server = useMemo(() => {
    return createServerClient({
      httpUrl: "https://tub-server.primodium.ai/trpc",
      wsUrl: "wss://tub-server.primodium.ai/trpc",
      httpHeaders: () => {
        return {
          Authorization: `Bearer xxx`,
        };
      },
    });
  }, []);

  return <ServerContext.Provider value={server}>{children}</ServerContext.Provider>;
};
