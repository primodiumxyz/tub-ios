import { endOfDay, startOfDay } from "date-fns";

export const PRICE_PRECISION = 1e9;

export const TIMESPAN_OPTIONS = ["10s", "30s", "1m", "2m", "5m", "10m", "30m", "1h", "1d"];
export const DEFAULT_TIMESPAN = "5m";
export const DEFAULT_MIN_TRADES = 0;
export const DEFAULT_MIN_VOLUME = 0;
export const DEFAULT_FREEZE_BURNT = true;
export const DEFAULT_MINT_BURNT = true;

export const DATE_PRESETS = [
  {
    label: "Past hour",
    getStart: () => new Date(new Date().getTime() - 1000 * 60 * 60),
    getEnd: () => new Date(),
  },
  { label: "Today", getStart: () => startOfDay(new Date()), getEnd: () => endOfDay(new Date()) },
  {
    label: "Past 7 days",
    getStart: () => endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 7)),
    getEnd: () => endOfDay(new Date()),
  },
  {
    label: "Past 30 days",
    getStart: () => endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 30)),
    getEnd: () => endOfDay(new Date()),
  },
];

export const DEFAULT_FROM = DATE_PRESETS[0].getStart();
export const DEFAULT_TO = DATE_PRESETS[0].getEnd();

// Performance
export const AFTER_INTERVALS = ["10s", "30s", "60s"]; // Intervals to measure the performance after the initial period
export const TOP_N_TOKENS = 10; // Amount of tokens to consider for performance
export enum SortByMetric {
  VOLUME = "volume",
  TRADES = "trades",
}

export const DEFAULT_SORT_BY = SortByMetric.VOLUME;
