import { useContext } from "react";

import { ServerContext, ServerContextType } from "@/providers/server-provider";

export const useServer = (): ServerContextType => {
  const context = useContext(ServerContext);
  if (!context) {
    throw new Error("useServer must be used within a ServerProvider");
  }
  return context;
};
