import { endOfDay, startOfDay } from "date-fns";

export const TIMESPAN_OPTIONS = ["10s", "30s", "1m", "2m", "5m", "10m", "30m", "1h", "1d"];
export const DEFAULT_TIMESPAN = TIMESPAN_OPTIONS[1];
export const DEFAULT_INCREASE_PCT = 5;
export const DEFAULT_MIN_TRADES = 10;

export const DEFAULT_FROM = startOfDay(new Date());
export const DEFAULT_TO = endOfDay(new Date());

export const DATE_PRESETS = [
  { label: "Today", start: startOfDay(new Date()), end: endOfDay(new Date()) },
  {
    label: "Last 7 days",
    start: endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 7)),
    end: endOfDay(new Date()),
  },
  {
    label: "Last 30 days",
    start: endOfDay(new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 30)),
    end: endOfDay(new Date()),
  },
];
