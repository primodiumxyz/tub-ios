import { Flame, Snowflake } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { TIMESPAN_OPTIONS } from "@/lib/constants";
import { cn } from "@/lib/utils";

import { Separator } from "../ui/separator";
import { useSidebar } from "../ui/sidebar";

export const TrackerParams = () => {
  const {
    timespan,
    minTrades,
    minVolume,
    freezeBurnt,
    mintBurnt,
    setTimespan,
    setMinTrades,
    setMinVolume,
    setFreezeBurnt,
    setMintBurnt,
  } = useTrackerParams();
  const { state } = useSidebar();

  return (
    <div className="flex flex-col gap-2 w-full items-center">
      <div
        className={cn("grid w-full max-w-md gap-1 text-start", state === "collapsed" && "pointer-events-none hidden")}
      >
        <Label htmlFor="timespan" className="px-4">
          Timespan
        </Label>
        <Select onValueChange={(value) => setTimespan(value)}>
          <SelectTrigger className="border-none">
            <SelectValue placeholder="Select a timespan" />
          </SelectTrigger>
          <SelectContent>
            {TIMESPAN_OPTIONS.map((option) => (
              <SelectItem key={option} value={option.toString()}>
                {option}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-gray-500 px-4">{timespan}</span>
      </div>
      <Separator className={cn(state === "collapsed" && "hidden")} />
      <div
        className={cn("grid w-full max-w-md gap-1 text-start", state === "collapsed" && "pointer-events-none hidden")}
      >
        <Label htmlFor="minVolume" className="px-4">
          Volume
        </Label>
        <Input
          type="number"
          id="minVolume"
          placeholder="Min. volume"
          onChange={(e) => setMinVolume(e.target.value)}
          className="border-none"
        />
        <span className="text-xs text-gray-500 px-4">{minVolume}</span>
      </div>
      <Separator className={cn(state === "collapsed" && "hidden")} />
      <div
        className={cn("grid w-full max-w-md gap-1 text-start", state === "collapsed" && "pointer-events-none hidden")}
      >
        <Label htmlFor="minTrades" className="text-start px-4">
          Minimum trades
        </Label>
        <Input
          type="number"
          id="minTrades"
          placeholder="Min. trades to consider"
          onChange={(e) => setMinTrades(e.target.value)}
          className="border-none"
        />
        <span className="text-xs text-gray-500 px-4">
          {">"} {minTrades}
        </span>
      </div>
      <Separator className={cn(state === "collapsed" && "hidden")} />
      <Button
        variant={mintBurnt ? "secondary" : "ghost"}
        onClick={() => setMintBurnt(!mintBurnt)}
        className={cn(
          "w-full flex justify-start px-2",
          !mintBurnt && "opacity-70",
          state === "collapsed" && "justify-center",
        )}
      >
        <Flame className="w-4 h-4" />
        <span className={cn(state === "collapsed" && "hidden")}>Mint burnt</span>
      </Button>
      <Button
        variant={freezeBurnt ? "secondary" : "ghost"}
        onClick={() => setFreezeBurnt(!freezeBurnt)}
        className={cn(
          "w-full flex justify-start px-2",
          !freezeBurnt && "opacity-70",
          state === "collapsed" && "justify-center",
        )}
      >
        <Snowflake className="w-4 h-4" />
        <span className={cn(state === "collapsed" && "hidden")}>Freeze burnt</span>
      </Button>
    </div>
  );
};
