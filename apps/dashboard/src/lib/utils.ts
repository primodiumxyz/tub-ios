import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

import { AFTER_INTERVALS, SortByMetric, TOP_N_TOKENS } from "@/lib/constants";
import { AggregatedStats, FilteredTokensPerformancePerIntervalData, TokenStats } from "@/lib/types";

export const cn = (...inputs: ClassValue[]) => {
  return twMerge(clsx(inputs));
};

export const getTokensPerformanceStats = (
  data: FilteredTokensPerformancePerIntervalData[],
  sortBy: SortByMetric = SortByMetric.TRADES,
): AggregatedStats => {
  const processedData = data
    .map((token) => ({
      ...token,
      increase_pct_after: (JSON.parse(token.increase_pct_after) ?? []) as number[],
      trades_after: (JSON.parse(token.trades_after) ?? []) as number[],
      volume_after: (JSON.parse(token.volume_after) ?? []) as number[],
    }))
    .sort((a, b) => {
      if (sortBy === SortByMetric.TRADES) {
        const sumTradesA = a.trades_after.reduce((sum, trades) => sum + trades, 0);
        const sumTradesB = b.trades_after.reduce((sum, trades) => sum + trades, 0);
        return sumTradesB - sumTradesA;
      } else {
        const sumVolumeA = a.volume_after.reduce((sum, volume) => sum + Number(volume), 0);
        const sumVolumeB = b.volume_after.reduce((sum, volume) => sum + Number(volume), 0);
        return sumVolumeB - sumVolumeA;
      }
    })
    .slice(0, TOP_N_TOKENS);

  const byInterval = new Map<string, TokenStats>();
  const globalAfterIntervals: Array<{
    increasePct: number[];
    trades: number[];
  }> = AFTER_INTERVALS.map(() => ({
    increasePct: [],
    trades: [],
  }));

  processedData.forEach((token) => {
    const intervalKey = token.interval_start.toString();
    const currentIntervalStats = byInterval.get(intervalKey) || {
      byAfterInterval: AFTER_INTERVALS.map(() => ({
        increasePct: {
          avg: 0,
          min: Infinity,
          max: -Infinity,
        },
        trades: {
          avg: 0,
          min: Infinity,
          max: -Infinity,
        },
        tokenCount: 0,
      })),
      tokenCount: 0,
    };

    token.increase_pct_after.forEach((increasePct, idx) => {
      const trades = token.trades_after[idx];
      const stats = currentIntervalStats.byAfterInterval[idx];

      stats.increasePct.avg = (stats.increasePct.avg * stats.tokenCount + increasePct) / (stats.tokenCount + 1);
      stats.increasePct.min = Math.min(stats.increasePct.min, increasePct);
      stats.increasePct.max = Math.max(stats.increasePct.max, increasePct);

      stats.trades.avg = (stats.trades.avg * stats.tokenCount + trades) / (stats.tokenCount + 1);
      stats.trades.min = Math.min(stats.trades.min, trades);
      stats.trades.max = Math.max(stats.trades.max, trades);

      stats.tokenCount++;

      globalAfterIntervals[idx].increasePct.push(increasePct);
      globalAfterIntervals[idx].trades.push(trades);
    });

    currentIntervalStats.tokenCount++;
    byInterval.set(intervalKey, currentIntervalStats);
  });

  const global: TokenStats = {
    byAfterInterval: globalAfterIntervals.map(({ increasePct, trades }) => ({
      increasePct: {
        avg: increasePct.reduce((a, b) => a + b, 0) / increasePct.length,
        min: Math.min(...increasePct),
        max: Math.max(...increasePct),
      },
      trades: {
        avg: trades.reduce((a, b) => a + b, 0) / trades.length,
        min: Math.min(...trades),
        max: Math.max(...trades),
      },
      tokenCount: increasePct.length,
    })),
    tokenCount: processedData.length,
  };

  return { byInterval, global };
};
