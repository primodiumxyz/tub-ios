import React, {
  createContext,
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";
import { createClient as createServerClient } from "@tub/server";

export type ServerContextType = {
  server: ReturnType<typeof createServerClient> | undefined;
  ready: boolean;
};

export const ServerContext = createContext<ServerContextType | undefined>(
  undefined
);

export const ServerProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const server = useRef<ReturnType<typeof createServerClient> | undefined>();
  const [ready, setReady] = useState(false);

  const createServer = useCallback(() => {
    server.current = createServerClient({
      httpUrl: "http://localhost:8080/trpc",
      wsUrl: "ws://localhost:8080/trpc",
    });
    setReady(true);
  }, []);

  useEffect(() => {
    createServer();
  }, [createServer]);

  const value = {
    server: server.current,
    ready,
  };

  return (
    <ServerContext.Provider value={value}>{children}</ServerContext.Provider>
  );
};
