import { useState } from "react";
import { BarChart3 } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { TokenChart } from "@/components/tracker/token-chart";
import { TokensTable } from "@/components/tracker/tokens-table";
import { Button } from "@/components/ui/button";
import { Token } from "@/lib/types";

/**
 * Component to display the tracker, which is the entire content of the dashboard
 *
 * @returns The tracker component
 */
export const Tracker = () => {
  const navigate = useNavigate();
  const [selectedToken, setSelectedToken] = useState<Token | null>(null);

  if (selectedToken) return <TokenChart token={selectedToken} onBack={() => setSelectedToken(null)} />;
  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4 p-4">
      <div className="flex items-center justify-between w-full">
        <h3 className="text-lg font-semibold">Pumping tokens</h3>
        <Button variant="ghost" className="gap-2" onClick={() => navigate("/analytics")}>
          <BarChart3 className="w-4 h-4" />
          Trades Analytics
        </Button>
      </div>
      <TokensTable onRowClick={(row) => setSelectedToken(row.original as Token)} />
    </div>
  );
};
