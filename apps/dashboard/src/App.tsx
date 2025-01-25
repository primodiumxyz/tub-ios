import { useMemo } from "react";
import { Provider as UrqlProvider } from "urql";

import { createClient as createGqlClient } from "@tub/gql";
import { Tracker } from "@/components/tracker";

import "@/App.css";

const dev = import.meta.env.VITE_USER_NODE_ENV !== "production";
const gqlClientUrl = dev ? "http://localhost:8090/v1/graphql" : (import.meta.env.VITE_GRAPHQL_URL! as string);

function App() {
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

  return (
    <UrqlProvider value={client}>
      <Tracker />
    </UrqlProvider>
  );
}

export default App;
