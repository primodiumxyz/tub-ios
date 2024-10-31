import { useMemo } from "react";
import { Route, BrowserRouter as Router, Routes } from "react-router-dom";
import { Provider as UrqlProvider } from "urql";

import { createClient as createGqlClient } from "@tub/gql";
import { Analytics } from "@/components/analytics";
import { AppSidebar } from "@/components/app-sidebar";
import { DataAnalysis } from "@/components/data-analysis";
import { Tracker } from "@/components/tracker";
import { SidebarProvider } from "@/components/ui/sidebar";
import { AnalyticsParamsProvider } from "@/providers/analytics-params-provider";
import { ServerProvider } from "@/providers/server-provider";
import { TrackerParamsProvider } from "@/providers/tracker-params-provider";

import "@/App.css";

const dev = (import.meta.env.VITE_NODE_ENV ?? "local") === "local";
const gqlClientUrl = dev ? "http://localhost:8080/v1/graphql" : (import.meta.env.VITE_GRAPHQL_URL! as string);

function App() {
  const client = useMemo(() => createGqlClient<"web">({ url: gqlClientUrl }).instance, []);

  return (
    <UrqlProvider value={client}>
      <ServerProvider>
        <TrackerParamsProvider>
          <AnalyticsParamsProvider>
            <SidebarProvider>
              <Router>
                <AppSidebar />
                <div className="flex flex-col items-center w-full">
                  <Routes>
                    <Route path="/" element={<Tracker />} />
                    <Route path="/analytics" element={<Analytics />} />
                    <Route path="/data-analysis" element={<DataAnalysis />} />
                  </Routes>
                </div>
              </Router>
            </SidebarProvider>
          </AnalyticsParamsProvider>
        </TrackerParamsProvider>
      </ServerProvider>
    </UrqlProvider>
  );
}

export default App;
