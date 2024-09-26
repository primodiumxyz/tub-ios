import { GqlClient } from "@tub/gql";
import { useContext } from "react";
import { GqlClientContext } from "../providers/GqlProvider";

export function useGql(): GqlClient {
  const gqlClient = useContext(GqlClientContext);

  if (!gqlClient) {
    throw new Error("useGQL must be used within a GQLProvider");
  }

  return gqlClient;
}
