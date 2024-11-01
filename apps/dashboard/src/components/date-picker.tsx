import { HTMLAttributes } from "react";
import { endOfDay, format, startOfDay } from "date-fns";
import { Calendar as CalendarIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { DATE_PRESETS } from "@/lib/constants";
import { cn } from "@/lib/utils";

export const DateRangePicker = ({ className }: HTMLAttributes<HTMLDivElement>) => {
  const { from, to, setFrom, setTo } = useAnalyticsParams();

  return (
    <div className={cn("grid gap-2", className)}>
      <Popover>
        <PopoverTrigger asChild>
          <Button
            id="date"
            variant={"outline"}
            className={cn("w-[300px] h-[76px] flex-col items-start", !from || (!to && "text-muted-foreground"))}
          >
            <div className="flex justify-start items-center text-left font-normal gap-2">
              <CalendarIcon />
              {from ? (
                to ? (
                  <>
                    {format(from, "LLL dd, y")} - {format(to, "LLL dd, y")}
                  </>
                ) : (
                  format(from, "LLL dd, y")
                )
              ) : (
                <span>Pick a date</span>
              )}
            </div>
            <span className="text-xs text-muted-foreground text-start">
              {format(from, "HH:mm")} - {format(to, "HH:mm")}
            </span>
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0" align="start">
          <Calendar
            initialFocus
            mode="range"
            defaultMonth={from}
            selected={{ from, to }}
            onSelect={(range) => {
              if (!range?.from || !range?.to) return;
              setFrom(startOfDay(range.from));
              setTo(endOfDay(range.to));
            }}
            numberOfMonths={2}
          />
        </PopoverContent>
      </Popover>
    </div>
  );
};

export const DatePresetsPicker = () => {
  const { setFrom, setTo } = useAnalyticsParams();
  return (
    <div className="grid grid-cols-2 gap-1">
      {DATE_PRESETS.map((preset) => (
        <Button
          variant="ghost"
          key={preset.label}
          onClick={() => {
            setFrom(preset.getStart());
            setTo(preset.getEnd());
          }}
        >
          {preset.label}
        </Button>
      ))}
    </div>
  );
};
