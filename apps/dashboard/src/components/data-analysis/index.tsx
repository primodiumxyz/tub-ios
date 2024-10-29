import { Loader2 } from "lucide-react";

import { PerformanceBasePeriodDataTable } from "@/components/data-analysis/performance-data";
import { DatePresetsPicker, DateRangePicker } from "@/components/date-picker";
import { TrackerParams } from "@/components/tracker/tracker-params";
import { Button } from "@/components/ui/button";
import { useDataAnalysisData } from "@/hooks/use-data-analysis";

export const DataAnalysis = () => {
  const { data, error, loading, refetch } = useDataAnalysisData();

  return (
    <div className="flex flex-col items-start w-full gap-6">
      <div className="flex justify-between gap-4 w-full">
        <h3 className="text-lg font-semibold">Data analysis</h3>
        <div className="flex gap-2">
          <DateRangePicker />
          <DatePresetsPicker />
        </div>
      </div>
      <TrackerParams />
      <Button disabled={loading} onClick={refetch} className="w-full">
        {loading ? (
          <div className="flex items-center gap-2">
            <Loader2 className="w-4 h-4 animate-spin" /> Querying...
          </div>
        ) : (
          "Query"
        )}
      </Button>
      {loading && <div className="w-full text-sm text-muted-foreground">This might take a while...</div>}
      {!!error && <div className="w-full text-sm text-muted-foreground">{error}</div>}
      {!!data && <PerformanceBasePeriodDataTable />}
    </div>
  );
};
