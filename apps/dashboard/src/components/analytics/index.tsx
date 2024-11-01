import { useMemo, useRef } from "react";

import { BasePeriodDataTable } from "@/components/analytics/base-period-data";
import { VolumeChart } from "@/components/analytics/volume-chart";
import { DatePresetsPicker, DateRangePicker } from "@/components/date-picker";
import { useAnalyticsData } from "@/hooks/use-analytics";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { useWindowDimensions } from "@/hooks/use-window-dimensions";

const MAX_POINTS_PER_CHART = 360;

export const Analytics = () => {
  const { volumeIntervals } = useAnalyticsData();
  const { timespan, minVolume, minTrades } = useTrackerParams();

  const containerRef = useRef<HTMLDivElement>(null);
  const { width } = useWindowDimensions();
  const chartWidth = useMemo(
    () => (containerRef.current?.clientWidth ?? 0) - 18,
    [containerRef.current?.clientWidth, width],
  );

  const chartGroups = useMemo(() => {
    if (!volumeIntervals.data) return [];

    const data = volumeIntervals.data;
    const groups: (typeof data)[] = [];

    for (let i = 0; i < data.length; i += MAX_POINTS_PER_CHART) {
      groups.push(data.slice(i, i + MAX_POINTS_PER_CHART));
    }

    return groups;
  }, [volumeIntervals.data]);

  return (
    <div ref={containerRef} className="flex flex-col items-start w-full gap-4">
      <div className="flex gap-2">
        <DateRangePicker />
        <DatePresetsPicker />
      </div>
      <BasePeriodDataTable />
      {!!volumeIntervals.data && !volumeIntervals.error && (
        <div className="w-full flex flex-col gap-4 items-center pt-8" style={{ width: chartWidth }}>
          {chartGroups.map((group, index) => (
            <div key={index} className="w-full flex flex-col items-center">
              <VolumeChart data={group} width={chartWidth} height={400} />
              {index === chartGroups.length - 1 && (
                <span className="block text-center text-sm text-muted-foreground mt-2">
                  Tokens with at least {minVolume} volume and at least {minTrades} trades, for each {timespan}
                  intervals over the specified period.
                </span>
              )}
            </div>
          ))}
        </div>
      )}
      {volumeIntervals.error && <div>{volumeIntervals.error}</div>}
    </div>
  );
};
