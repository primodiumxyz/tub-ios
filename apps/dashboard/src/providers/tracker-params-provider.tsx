import React, { createContext, useContext, useState } from "react";

import {
  DEFAULT_FREEZE_BURNT,
  DEFAULT_MIN_TRADES,
  DEFAULT_MIN_VOLUME,
  DEFAULT_MINT_BURNT,
  DEFAULT_TIMESPAN,
} from "@/lib/constants";

export type TrackerParams = {
  timespan: string;
  minTrades: number;
  minVolume: number;
  freezeBurnt: boolean;
  mintBurnt: boolean;
};

type TrackerParamsContextType = {
  params: TrackerParams;
  setTimespan: (value: string) => void;
  setMinTrades: (value: number) => void;
  setMinVolume: (value: number) => void;
  setFreezeBurnt: (value: boolean) => void;
  setMintBurnt: (value: boolean) => void;
};

const TrackerParamsContext = createContext<TrackerParamsContextType | undefined>(undefined);

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export const TrackerParamsProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [params, setParams] = useState<TrackerParams>({
    timespan: DEFAULT_TIMESPAN,
    minTrades: DEFAULT_MIN_TRADES,
    minVolume: DEFAULT_MIN_VOLUME,
    freezeBurnt: DEFAULT_FREEZE_BURNT,
    mintBurnt: DEFAULT_MINT_BURNT,
  });

  const setTimespan = (value: string) => setParams((prev) => ({ ...prev, timespan: value }));
  const setMinTrades = (value: number) => setParams((prev) => ({ ...prev, minTrades: value }));
  const setMinVolume = (value: number) => setParams((prev) => ({ ...prev, minVolume: value }));
  const setFreezeBurnt = (value: boolean) => setParams((prev) => ({ ...prev, freezeBurnt: value }));
  const setMintBurnt = (value: boolean) => setParams((prev) => ({ ...prev, mintBurnt: value }));

  return (
    <TrackerParamsContext.Provider
      value={{ params, setTimespan, setMinTrades, setMinVolume, setFreezeBurnt, setMintBurnt }}
    >
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
