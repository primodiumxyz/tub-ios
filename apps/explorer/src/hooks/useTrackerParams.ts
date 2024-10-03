import { useState } from "react";

import { DEFAULT_INCREASE_PCT, DEFAULT_MIN_TRADES, DEFAULT_TIMESPAN } from "@/lib/constants";

export const useTrackerParams = () => {
  const [timespan, _setTimespan] = useState(DEFAULT_TIMESPAN);
  const [increasePct, _setIncreasePct] = useState(DEFAULT_INCREASE_PCT);
  const [minTrades, _setMinTrades] = useState(DEFAULT_MIN_TRADES);

  const setTimespan = (value: string | number) => {
    if (isNaN(Number(value))) return;
    _setTimespan(Number(value));
  };

  const setIncreasePct = (value: string | number) => {
    if (isNaN(Number(value))) return;
    _setIncreasePct(Number(value));
  };

  const setMinTrades = (value: string | number) => {
    if (isNaN(Number(value))) return;
    _setMinTrades(Number(value));
  };

  return {
    timespan,
    increasePct,
    minTrades,
    setTimespan,
    setIncreasePct,
    setMinTrades,
  };
};
