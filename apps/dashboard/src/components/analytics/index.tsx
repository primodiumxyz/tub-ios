import { useMemo, useRef } from "react";

import { BasePeriodDataTable } from "@/components/analytics/base-period-data";
import { DatePresetsPicker, DateRangePicker } from "@/components/analytics/date-picker";
import { FilteredTokensChart } from "@/components/analytics/filtered-tokens-period-chart";
import { TrackerParams } from "@/components/tracker/tracker-params";
import { Separator } from "@/components/ui/separator";
import { useAnalyticsData } from "@/hooks/use-analytics";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { useWindowDimensions } from "@/hooks/use-window-dimensions";

const MAX_POINTS_PER_CHART = 360;

export const Analytics = () => {
  const { filteredTokensPerInterval } = useAnalyticsData();
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const containerRef = useRef<HTMLDivElement>(null);
  const { width } = useWindowDimensions();
  const chartWidth = useMemo(
    () => (containerRef.current?.clientWidth ?? 0) - 18,
    [containerRef.current?.clientWidth, width],
  );

  const chartGroups = useMemo(() => {
    if (!filteredTokensPerInterval.data) return [];

    const data = filteredTokensPerInterval.data;
    const groups: (typeof data)[] = [];

    for (let i = 0; i < data.length; i += MAX_POINTS_PER_CHART) {
      groups.push(data.slice(i, i + MAX_POINTS_PER_CHART));
    }

    return groups;
  }, [filteredTokensPerInterval.data]);

  return (
    <div ref={containerRef} className="flex flex-col items-start w-full gap-4">
      <div className="flex justify-between gap-4 w-full">
        <h3 className="text-lg font-semibold">Analytics</h3>
        <div className="flex gap-2">
          <DateRangePicker />
          <DatePresetsPicker />
        </div>
      </div>
      <BasePeriodDataTable />
      <Separator className="my-4" />
      <TrackerParams />
      {!!filteredTokensPerInterval.data && !filteredTokensPerInterval.error && (
        <div className="w-full flex flex-col gap-4 items-center pt-8" style={{ width: chartWidth }}>
          {chartGroups.map((group, index) => (
            <div key={index} className="w-full flex flex-col items-center">
              <FilteredTokensChart data={group} width={chartWidth} height={400} />
              {index === chartGroups.length - 1 && (
                <span className="block text-center text-sm text-muted-foreground mt-2">
                  Tokens pumping at least {increasePct}% with minimum {minTrades} trades, for each {timespan} intervals
                  over the specified period.
                </span>
              )}
            </div>
          ))}
        </div>
      )}
      {filteredTokensPerInterval.error && <div>{filteredTokensPerInterval.error}</div>}
    </div>
  );
};
