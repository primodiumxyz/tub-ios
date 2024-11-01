import { Flame, Snowflake } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { TIMESPAN_OPTIONS } from "@/lib/constants";
import { cn } from "@/lib/utils";

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
  return (
    <div className="grid xs:grid-cols-2 sm:grid-cols-3 xl:grid-cols-[1fr_1fr_1fr_auto_auto] gap-2 w-full items-center">
      <div className="grid w-full max-w-md gap-1 text-start">
        <Label htmlFor="timespan">Timespan</Label>
        <Select onValueChange={(value) => setTimespan(value)}>
          <SelectTrigger>
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
        <span className="text-xs text-gray-500">{timespan}</span>
      </div>
      <div className="grid w-full max-w-md gap-1 text-start">
        <Label htmlFor="minVolume">Volume</Label>
        <Input type="number" id="minVolume" placeholder="Min. volume" onChange={(e) => setMinVolume(e.target.value)} />
        <span className="text-xs text-gray-500">{minVolume}</span>
      </div>
      <div className="grid w-full max-w-md gap-1 text-start">
        <Label htmlFor="minTrades" className="text-start">
          Minimum trades
        </Label>
        <Input
          type="number"
          id="minTrades"
          placeholder="Min. trades to consider"
          onChange={(e) => setMinTrades(e.target.value)}
        />
        <span className="text-xs text-gray-500">
          {">"} {minTrades}
        </span>
      </div>
      <Button
        variant={mintBurnt ? "secondary" : "ghost"}
        onClick={() => setMintBurnt(!mintBurnt)}
        className={cn(!mintBurnt && "opacity-70")}
      >
        <Flame className="w-4 h-4" />
        <span>Mint burnt</span>
      </Button>
      <Button
        variant={freezeBurnt ? "secondary" : "ghost"}
        onClick={() => setFreezeBurnt(!freezeBurnt)}
        className={cn(!freezeBurnt && "opacity-70")}
      >
        <Snowflake className="w-4 h-4" />
        <span>Freeze burnt</span>
      </Button>
    </div>
  );
};
