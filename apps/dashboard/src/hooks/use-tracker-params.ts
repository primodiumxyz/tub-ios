import { useTrackerParamsContext } from "@/providers/tracker-params-provider";

export const useTrackerParams = () => {
  const { params, setTimespan, setMinTrades, setMinVolume, setFreezeBurnt, setMintBurnt } = useTrackerParamsContext();

  return {
    timespan: params.timespan,
    minTrades: params.minTrades,
    minVolume: params.minVolume,
    freezeBurnt: params.freezeBurnt,
    mintBurnt: params.mintBurnt,
    setTimespan: (value: string) => {
      setTimespan(value);
    },
    setMinTrades: (value: string | number) => {
      const numValue = typeof value === "string" ? parseFloat(value) : value;
      if (!isNaN(numValue)) {
        setMinTrades(numValue);
      }
    },
    setMinVolume: (value: string | number) => {
      const numValue = typeof value === "string" ? parseFloat(value) : value;
      if (!isNaN(numValue)) {
        setMinVolume(numValue);
      }
    },
    setFreezeBurnt: (value: boolean) => {
      setFreezeBurnt(value);
    },
    setMintBurnt: (value: boolean) => {
      setMintBurnt(value);
    },
  };
};
