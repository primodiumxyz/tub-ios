import { useTrackerParamsContext } from "@/providers/TrackerParamsProvider";

export const useTrackerParams = () => {
  const { params, setTimespan, setIncreasePct, setMinTrades } = useTrackerParamsContext();

  return {
    timespan: params.timespan,
    increasePct: params.increasePct,
    minTrades: params.minTrades,
    setTimespan: (value: string | number) => {
      const numValue = typeof value === "string" ? parseFloat(value) : value;
      if (!isNaN(numValue)) {
        setTimespan(numValue);
      }
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
