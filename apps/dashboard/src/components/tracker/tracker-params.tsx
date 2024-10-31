import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useTrackerParams } from "@/hooks/use-tracker-params";
import { TIMESPAN_OPTIONS } from "@/lib/constants";

export const TrackerParams = () => {
  const { timespan, minTrades, minVolume, setTimespan, setMinTrades, setMinVolume } = useTrackerParams();

  return (
    <div className="grid xs: grid-cols-2 sm:grid-cols-3 gap-2 w-full items-start">
      <div className="grid w-full max-w-md gap-1.5 text-start">
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
      <div className="grid w-full max-w-md gap-1.5 text-start">
        <Label htmlFor="minVolume">Volume</Label>
        <Input type="number" id="minVolume" placeholder="Min. volume" onChange={(e) => setMinVolume(e.target.value)} />
        <span className="text-xs text-gray-500">{minVolume}</span>
      </div>
      <div className="grid w-full max-w-md gap-1.5 text-start">
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
    </div>
  );
};
