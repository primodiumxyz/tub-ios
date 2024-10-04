import React, { createContext, useMemo } from "react";
import { createClient as createServerClient } from "@tub/server";
import { useUserStore } from "../store/userStore";

export type ServerContextType = ReturnType<typeof createServerClient>;

export const ServerContext = createContext<ServerContextType | null>(null);

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const server = useMemo(() => {
    return createServerClient({
      httpUrl: "http://localhost:8080/trpc",
      wsUrl: "ws://localhost:8080/trpc",
      httpHeaders: () => {
        const jwtToken = useUserStore.getState().jwtToken;
        return {
          Authorization: `Bearer ${jwtToken}`,
        }
      }
    });
  }, []);

  return (
    <ServerContext.Provider value={server}>{children}</ServerContext.Provider>
  );
};
