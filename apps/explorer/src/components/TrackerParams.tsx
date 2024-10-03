import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useTrackerParams } from "@/hooks/useTrackerParams";
import { formatTime } from "@/lib/utils";

export const TrackerParams = () => {
  const { timespan, increasePct, minTrades, setTimespan, setIncreasePct, setMinTrades } = useTrackerParams();

  return (
    <div className="grid xs: grid-cols-2 sm:grid-cols-3 gap-2 w-full">
      <div className="grid w-full max-w-md gap-1.5 text-start">
        <Label htmlFor="timespan">Timespan</Label>
        <Input
          type="number"
          id="timespan"
          placeholder="Timespan in seconds"
          onChange={(e) => setTimespan(e.target.value)}
        />
        <span className="text-xs text-gray-500">{formatTime(timespan)}</span>
      </div>
      <div className="grid w-full max-w-md gap-1.5 text-start">
        <Label htmlFor="increasePct">Price increase</Label>
        <Input
          type="number"
          id="increasePct"
          placeholder="Price increase in %"
          onChange={(e) => setIncreasePct(e.target.value)}
        />
        <span className="text-xs text-gray-500">{increasePct}%</span>
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
