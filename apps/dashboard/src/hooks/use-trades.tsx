import { useMemo } from "react";
import { useSubscription } from "urql";

import { subscriptions } from "@tub/gql";
import { GroupedTrade, Trade, TradeFilters } from "@/lib/types";

type UseTradesResult = {
  trades: GroupedTrade[];
  fetching: boolean;
  error: string | undefined;
};

/**
 * Hook to get the updated trades for a given user wallet or token mint
 *
 * @param filters - The filters to apply to the trades
 * @returns The trades with loading & error state {@link UseTradesResult}
 */
export const useTrades = (filters: TradeFilters = { limit: 1000 }): UseTradesResult => {
  const [tradesRes] = useSubscription({
    query: filters.userWalletOrTokenMint
      ? subscriptions.GetTradesByUserWalletOrTokenMintSubscription
      : subscriptions.GetTradesSubscription,
    // @ts-expect-error unexpected variables
    variables: filters.userWalletOrTokenMint
      ? { userWalletOrTokenMint: filters.userWalletOrTokenMint, limit: filters.limit }
      : { limit: filters.limit },
  });

  return useMemo(() => {
    const rawTrades: Trade[] =
      tradesRes.data?.transactions.map((t) => {
        const tokenAmount = Number(t.token_amount) / 10 ** t.token_decimals;

        return {
          id: t.id,
          timestamp: new Date(t.created_at).getTime(),
          userWallet: t.user_wallet,
          token: t.token_mint,
          price: Number(t.token_price_usd),
          amount: Math.abs(tokenAmount),
          value: Number(t.token_value_usd) / 10 ** t.token_decimals,
          type: tokenAmount > 0 ? "buy" : "sell",
          success: t.success,
          error: t.error_details,
        };
      }) ?? [];

    // Group trades by token & date
    const tradesByTokenAndDate = rawTrades.reduce(
      (acc, trade) => {
        const date = new Date(trade.timestamp);
        date.setHours(0, 0, 0, 0);
        const key = `${trade.token}_${date.getTime()}`;
        if (!acc[key]) acc[key] = [];
        acc[key].push(trade);
        return acc;
      },
      {} as Record<string, Trade[]>,
    );

    // Create grouped trades
    const groupedTrades: GroupedTrade[] = Object.entries(tradesByTokenAndDate).map(([, trades]) => {
      const sortedTrades = trades.sort((a, b) => b.timestamp - a.timestamp);
      const firstTrade = sortedTrades[0];

      // Collect all unique errors from failed sells only
      const failedSells = trades.filter((t) => t.type === "sell" && !t.success);

      const errors = failedSells
        .filter((t) => t.error)
        .reduce(
          (acc, t) => {
            const count = acc.find((e) => e.message === t.error)?.count ?? 0;
            if (count > 0) {
              return acc.map((e) => (e.message === t.error ? { ...e, count: e.count + 1 } : e));
            }
            return [...acc, { message: t.error!, count: 1 }];
          },
          [] as Array<{ message: string; count: number }>,
        );

      // Format error message
      const errorMessage =
        errors.length > 0 ? errors.map((e) => `${e.message}${e.count > 1 ? ` (x${e.count})` : ""}`).join("\n") : null;

      // Determine group status
      const hasErrors = failedSells.length > 0;
      const hasSells = trades.some((t) => t.type === "sell" && t.success);
      const status = hasErrors ? "error" : hasSells ? "filled" : "open";

      return {
        id: firstTrade.id,
        token: firstTrade.token,
        userWallet: firstTrade.userWallet,
        timestamp: firstTrade.timestamp,
        trades: sortedTrades,
        netProfit: trades.filter((t) => t.success).reduce((sum, t) => sum - t.value, 0),
        status,
        error: errorMessage,
        failedSellCount: failedSells.length, // Add this to help debug
      };
    });

    // Sort groups by timestamp (most recent first)
    const sortedGroupedTrades = groupedTrades.sort((a, b) => b.timestamp - a.timestamp);

    return {
      trades: sortedGroupedTrades,
      fetching: tradesRes.fetching,
      error: tradesRes.error?.message,
    };
  }, [tradesRes.data, tradesRes.fetching, tradesRes.error, filters]);
};
