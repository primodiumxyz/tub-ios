import React, { createContext, useContext, useState } from "react";

import { DEFAULT_FROM, DEFAULT_TO } from "@/lib/constants";

export type AnalyticsParams = {
  from: Date;
  to: Date;
  periodMs: number;
};

type AnalyticsParamsContextType = {
  params: AnalyticsParams;
  setFrom: (value: Date) => void;
  setTo: (value: Date) => void;
  setPeriodMs: (value: number) => void;
};

const AnalyticsParamsContext = createContext<AnalyticsParamsContextType | undefined>(undefined);

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
export const AnalyticsParamsProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [params, setParams] = useState<AnalyticsParams>({
    from: DEFAULT_FROM,
    to: DEFAULT_TO,
    periodMs: DEFAULT_TO.getTime() - DEFAULT_FROM.getTime(),
  });

  const setFrom = (value: Date) => setParams((prev) => ({ ...prev, from: value }));
  const setTo = (value: Date) => setParams((prev) => ({ ...prev, to: value }));
  const setPeriodMs = (value: number) => setParams((prev) => ({ ...prev, periodMs: value }));
  return (
    <AnalyticsParamsContext.Provider value={{ params, setFrom, setTo, setPeriodMs }}>
      {children}
    </AnalyticsParamsContext.Provider>
  );
};

export const useAnalyticsParamsContext = () => {
  const context = useContext(AnalyticsParamsContext);
  if (context === undefined) {
    throw new Error("useAnalyticsParams must be used within a AnalyticsParamsProvider");
  }
  return context;
};
