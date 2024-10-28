import { BasePeriodDataTable } from "@/components/analytics/base-period-data";
import { DatePresetsPicker, DateRangePicker } from "@/components/analytics/date-picker";
import { FilteredTokensPeriodDataTable } from "@/components/analytics/filtered-tokens-period-data";
import { TrackerParams } from "@/components/tracker/tracker-params";
import { Separator } from "@/components/ui/separator";

export const Analytics = () => {
  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4">
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
      <FilteredTokensPeriodDataTable />
    </div>
  );
};
