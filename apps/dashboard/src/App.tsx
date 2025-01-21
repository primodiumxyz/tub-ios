import { useMemo } from "react";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Provider as UrqlProvider } from "urql";

import { createClient as createGqlClient } from "@tub/gql";
import { Analytics } from "@/components/analytics";
import { Tracker } from "@/components/tracker";
import { ServerProvider } from "@/providers/server-provider";

import "@/App.css";

const dev = import.meta.env.VITE_USER_NODE_ENV !== "production";
const gqlClientUrl = dev ? "http://localhost:8090/v1/graphql" : (import.meta.env.VITE_GRAPHQL_URL! as string);

function App() {
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

  return (
    <BrowserRouter>
      <UrqlProvider value={client}>
        <ServerProvider>
          <div className="flex flex-col w-full h-full">
            <Routes>
              <Route path="/" element={<Tracker />} />
              <Route path="/analytics" element={<Analytics />} />
            </Routes>
          </div>
        </ServerProvider>
      </UrqlProvider>
    </BrowserRouter>
  );
}

export default App;
