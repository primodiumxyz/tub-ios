import { endOfDay, endOfHour, startOfDay } from "date-fns";

export const PRICE_PRECISION = 1e9;

export const TIMESPAN_OPTIONS = ["10s", "30s", "1m", "2m", "5m", "10m", "30m", "1h", "1d"];
export const DEFAULT_TIMESPAN = TIMESPAN_OPTIONS[1];
export const DEFAULT_INCREASE_PCT = 5;
export const DEFAULT_MIN_TRADES = 10;

export const DATE_PRESETS = [
  { label: "Past hour", start: endOfHour(new Date(new Date().getTime() - 1000 * 60 * 60)), end: endOfHour(new Date()) },
  { label: "Today", start: startOfDay(new Date()), end: endOfDay(new Date()) },
  {
    label: "Past 7 days",
    start: endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 7)),
    end: endOfDay(new Date()),
  },
  {
    label: "Past 30 days",
    start: endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 30)),
    end: endOfDay(new Date()),
  },
];

export const DEFAULT_FROM = DATE_PRESETS[0].start;
export const DEFAULT_TO = DATE_PRESETS[0].end;

// Performance
export const AFTER_INTERVALS = ["10s", "30s", "60s"]; // Intervals to measure the performance after the initial period
