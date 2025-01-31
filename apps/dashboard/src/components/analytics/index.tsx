import { LineChart } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { Stats } from "@/components/analytics/stats";
import { TradesTable } from "@/components/analytics/trades-table";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";

/**
 * Component to display the analytics page
 *
 * @returns The analytics component
 */
export const Analytics = () => {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4 p-4">
      <div className="flex items-center justify-between w-full">
        <h3 className="text-lg font-semibold">Trades analytics</h3>
        <Button variant="ghost" className="gap-2" onClick={() => navigate("/")}>
          <LineChart className="w-4 h-4" />
          Pumping Tokens
        </Button>
      </div>
      <Stats />
      <Separator />
      <TradesTable />
    </div>
  );
};
