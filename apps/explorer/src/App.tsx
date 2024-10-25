import { useMemo } from "react";
import { Provider as UrqlProvider } from "urql";

import { createClient as createGqlClient } from "@tub/gql";
import { AppSidebar } from "@/components/AppSidebar";
import { Tracker } from "@/components/Tracker";
import { SidebarProvider } from "@/components/ui/sidebar";
import { ServerProvider } from "@/providers/ServerProvider";
import { TrackerParamsProvider } from "@/providers/TrackerParamsProvider";

import "@/App.css";

const dev = (import.meta.env.VITE_NODE_ENV ?? "local") === "local";
const gqlClientUrl = dev ? "http://localhost:8080/v1/graphql" : (import.meta.env.VITE_GRAPHQL_URL! as string);

function App() {
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

  return (
    <UrqlProvider value={client}>
      <ServerProvider>
        <TrackerParamsProvider>
          <SidebarProvider>
            <AppSidebar />
            <div className="flex flex-col items-center">
              <Tracker />
            </div>
          </SidebarProvider>
        </TrackerParamsProvider>
      </ServerProvider>
    </UrqlProvider>
  );
}

export default App;
