export type FilteredTokensPerformancePerIntervalData = {
  mint: string;
  increase_pct: string;
  trades: string;
  increase_pct_after: string;
  trades_after: string;
  created_at: Date;
  interval_start: Date;
};

export type AggregatedStats = {
  byInterval: Map<string, TokenStats>; // key is interval_start
  global: TokenStats;
};

export type TokenStats = {
  byAfterInterval: IntervalStats[];
  tokenCount: number;
};

type IntervalStats = {
  increasePct: {
    avg: number;
    min: number;
    max: number;
  };
  trades: {
    avg: number;
    min: number;
    max: number;
  };
  tokenCount: number;
};
