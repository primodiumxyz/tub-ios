import { useContext } from "react";
import { ServerContext, ServerContextType } from "../contexts/serverContext";

export const useServer = (): ServerContextType => {
  const context = useContext(ServerContext);
  if (context === undefined) {
    throw new Error("useServer must be used within a ServerProvider");
  }
  return context;
};
