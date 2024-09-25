import { useContext } from "react";
import { ClientContext } from "../providers/GQLProvider";
import { createClient } from "@tub/gql";

export function useGql() : ReturnType<typeof createClient> {
  const client = useContext(ClientContext);

  if (!client) {
    throw new Error("useGQL must be used within a GQLProvider");
  }

  return client;
}
