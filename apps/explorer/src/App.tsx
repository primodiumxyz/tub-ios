import { useMemo } from "react";
import { Provider as UrqlProvider } from "urql";

import { createClient as createGqlClient } from "@tub/gql";
import { Tracker } from "@/components/Tracker";
import { ServerProvider } from "@/providers/ServerProvider";
import { TrackerParamsProvider } from "@/providers/TrackerParamsProvider";

import "@/App.css";

const gqlClientUrl = import.meta.env.VITE_GRAPHQL_URL! as string;

function App() {
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

  return (
    <UrqlProvider value={client}>
      <ServerProvider>
        <TrackerParamsProvider>
          <div className="flex flex-col items-center">
            <Tracker />
          </div>
        </TrackerParamsProvider>
      </ServerProvider>
    </UrqlProvider>
  );
}

export default App;
