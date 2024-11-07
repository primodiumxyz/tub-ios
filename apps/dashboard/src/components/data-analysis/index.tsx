import { useMemo, useRef } from "react";
import { Loader2 } from "lucide-react";

import { PerformanceBasePeriodDataTable } from "@/components/data-analysis/performance-data";
import { DatePresetsPicker, DateRangePicker } from "@/components/date-picker";
import { TrackerParams } from "@/components/tracker/tracker-params";
import { Button } from "@/components/ui/button";
import { useDataAnalysisData } from "@/hooks/use-data-analysis";
import { useWindowDimensions } from "@/hooks/use-window-dimensions";

export const DataAnalysis = () => {
  const { loading, refetch } = useDataAnalysisData();
  const containerRef = useRef<HTMLDivElement>(null);
  const { width } = useWindowDimensions();

  const chartWidth = useMemo(
    () => (containerRef.current?.clientWidth ?? 0) - 18,
    [containerRef.current?.clientWidth, width],
  );

  return (
    <div ref={containerRef} className="flex flex-col items-start w-full gap-6">
      <div className="flex gap-2">
        <DateRangePicker />
        <DatePresetsPicker />
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
      <PerformanceBasePeriodDataTable chartWidth={chartWidth} />
    </div>
  );
};
