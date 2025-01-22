import { ColumnDef } from "@tanstack/react-table";
import { formatDistanceStrict } from "date-fns";
import { AlertCircle, ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

import { ExplorerLink } from "@/components/explorer-link";
import { Button } from "@/components/ui/button";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { GroupedTrade } from "@/lib/types";
import { formatUsd } from "@/lib/utils";

export const columns: ColumnDef<GroupedTrade>[] = [
  {
    accessorKey: "token",
    header: "Token",
    cell: ({ row }) => {
      const firstTrade = row.original.trades[0];
      return (
        <ExplorerLink address={firstTrade.token} url={`https://photon-sol.tinyastro.io/en/lp/${firstTrade.token}`} />
      );
    },
  },
  {
    accessorKey: "userWallet",
    header: "User",
    cell: ({ row }) => {
      const firstTrade = row.original.trades[0];
      return (
        <ExplorerLink address={firstTrade.userWallet} url={`https://solscan.io/account/${firstTrade.userWallet}`} />
      );
    },
  },
  {
    accessorKey: "buyInfo",
    header: "Buy",
    cell: ({ row }) => {
      const buyTrade = row.original.trades.find((t) => t.type === "buy");
      if (!buyTrade) return null;

      return (
        <div className="flex flex-col">
          <span>{formatUsd(buyTrade.value)}</span>
          <span className="text-xs text-muted-foreground">{new Date(buyTrade.timestamp).toLocaleString()}</span>
        </div>
      );
    },
  },
  {
    accessorKey: "sellInfo",
    header: "Sell",
    cell: ({ row }) => {
      const { trades, error } = row.original;
      const successfulSell = trades.find((t) => t.type === "sell" && t.success);
      const failedSells = trades.filter((t) => t.type === "sell" && !t.success);

      return (
        <div className="flex flex-col">
          <div className="flex items-center gap-2">
            {successfulSell ? (
              <div className="flex flex-col">
                <span>{formatUsd(Math.abs(successfulSell.value))}</span>
                <span className="text-xs text-muted-foreground">
                  {new Date(successfulSell.timestamp).toLocaleString()}
                </span>
              </div>
            ) : (
              <div className="flex items-center gap-2">
                <span className="text-yellow-500">Open Position</span>
                {error && (
                  <Tooltip>
                    <TooltipTrigger className="flex items-center gap-1 py-1 bg-transparent text-destructive text-sm w-fit">
                      <AlertCircle className="h-4 w-4" /> x{failedSells.length}
                    </TooltipTrigger>
                    <TooltipContent>
                      {error.split("\n").map((err, i) => (
                        <div key={i}>{err}</div>
                      ))}
                    </TooltipContent>
                  </Tooltip>
                )}
              </div>
            )}
          </div>
        </div>
      );
    },
  },
  {
    accessorKey: "duration",
    header: "Duration",
    cell: ({ row }) => {
      const { trades } = row.original;
      const buyTrade = trades.find((t) => t.type === "buy");
      const successfulSell = trades.find((t) => t.type === "sell" && t.success);

      if (!buyTrade) return "-";

      const endTime = successfulSell ? new Date(successfulSell.timestamp) : new Date();
      return formatDistanceStrict(new Date(buyTrade.timestamp), endTime);
    },
  },
  {
    accessorKey: "netProfit",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Net Profit
        <Button
          variant="ghost"
          className="h-8 w-8 p-0"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="h-4 w-4" />
            ) : (
              <ArrowDown className="h-4 w-4" />
            )
          ) : (
            <ArrowUpDown className="h-4 w-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => {
      const { netProfit, trades } = row.original;
      const successfulSell = trades.find((t) => t.type === "sell" && t.success);
      if (!successfulSell) return "-";

      return (
        <span className={netProfit >= 0 ? "text-green-500" : "text-red-500"}>
          {netProfit >= 0 ? "+" : ""}
          {formatUsd(netProfit)}
        </span>
      );
    },
  },
];
