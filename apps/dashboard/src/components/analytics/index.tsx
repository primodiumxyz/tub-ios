import { LineChart } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { TradesTable } from "@/components/analytics/trades-table";
import { Button } from "@/components/ui/button";

export const Analytics = () => {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4 p-4">
      <div className="flex items-center justify-between w-full">
        <h3 className="text-lg font-semibold">User analytics</h3>
        <Button variant="ghost" className="gap-2" onClick={() => navigate("/")}>
          <LineChart className="w-4 h-4" />
          Pumping Tokens
        </Button>
      </div>
      <TradesTable />
    </div>
  );
};
