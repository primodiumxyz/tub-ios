import React, { createContext, useContext, useState } from "react";

import { DEFAULT_INCREASE_PCT, DEFAULT_MIN_TRADES, DEFAULT_TIMESPAN } from "@/lib/constants";

export type TrackerParams = {
  timespan: string;
  increasePct: number;
  minTrades: number;
};

type TrackerParamsContextType = {
  params: TrackerParams;
  setTimespan: (value: string) => void;
  setIncreasePct: (value: number) => void;
  setMinTrades: (value: number) => void;
};

const TrackerParamsContext = createContext<TrackerParamsContextType | undefined>(undefined);

export const TrackerParamsProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [params, setParams] = useState<TrackerParams>({
    timespan: DEFAULT_TIMESPAN,
    increasePct: DEFAULT_INCREASE_PCT,
    minTrades: DEFAULT_MIN_TRADES,
  });

  const setTimespan = (value: string) => setParams((prev) => ({ ...prev, timespan: value }));
  const setIncreasePct = (value: number) => setParams((prev) => ({ ...prev, increasePct: value }));
  const setMinTrades = (value: number) => setParams((prev) => ({ ...prev, minTrades: value }));

  return (
    <TrackerParamsContext.Provider value={{ params, setTimespan, setIncreasePct, setMinTrades }}>
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
