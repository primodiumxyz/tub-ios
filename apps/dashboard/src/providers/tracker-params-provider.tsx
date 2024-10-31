import React, { createContext, useContext, useState } from "react";

import { DEFAULT_MIN_TRADES, DEFAULT_MIN_VOLUME, DEFAULT_TIMESPAN } from "@/lib/constants";

export type TrackerParams = {
  timespan: string;
  minTrades: number;
  minVolume: number;
};

type TrackerParamsContextType = {
  params: TrackerParams;
  setTimespan: (value: string) => void;
  setMinTrades: (value: number) => void;
  setMinVolume: (value: number) => void;
};

const TrackerParamsContext = createContext<TrackerParamsContextType | undefined>(undefined);

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export const TrackerParamsProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [params, setParams] = useState<TrackerParams>({
    timespan: DEFAULT_TIMESPAN,
    minTrades: DEFAULT_MIN_TRADES,
    minVolume: DEFAULT_MIN_VOLUME,
  });

  const setTimespan = (value: string) => setParams((prev) => ({ ...prev, timespan: value }));
  const setMinTrades = (value: number) => setParams((prev) => ({ ...prev, minTrades: value }));
  const setMinVolume = (value: number) => setParams((prev) => ({ ...prev, minVolume: value }));

  return (
    <TrackerParamsContext.Provider value={{ params, setTimespan, setMinTrades, setMinVolume }}>
      {children}
    </TrackerParamsContext.Provider>
  );
};

export const useTrackerParamsContext = () => {
  const context = useContext(TrackerParamsContext);
  if (context === undefined) {
    throw new Error("useTrackerParams must be used within a TrackerParamsProvider");
  }
  return context;
};
