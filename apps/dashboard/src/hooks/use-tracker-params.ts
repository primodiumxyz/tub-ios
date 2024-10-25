import { useTrackerParamsContext } from "@/providers/tracker-params-provider";

export const useTrackerParams = () => {
  const { params, setTimespan, setIncreasePct, setMinTrades } = useTrackerParamsContext();

  return {
    timespan: params.timespan,
    increasePct: params.increasePct,
    minTrades: params.minTrades,
    setTimespan: (value: string) => {
      setTimespan(value);
    },
    setIncreasePct: (value: string | number) => {
      const numValue = typeof value === "string" ? parseFloat(value) : value;
      if (!isNaN(numValue)) {
        setIncreasePct(numValue);
      }
    },
    setMinTrades: (value: string | number) => {
      const numValue = typeof value === "string" ? parseFloat(value) : value;
      if (!isNaN(numValue)) {
        setMinTrades(numValue);
      }
    },
  };
};
