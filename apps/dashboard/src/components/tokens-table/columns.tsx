import { ColumnDef } from "@tanstack/react-table";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Interval, Token } from "@/lib/types";
import { formatLargeNumber } from "@/lib/utils";

export const getColumns = (selectedInterval: Interval): ColumnDef<Token>[] => [
  {
    accessorKey: "mint",
    header: "Token",
    cell: ({ row }) => {
      const token = row.original;
      return (
        <div className="flex items-center gap-2">
          {token.imageUri && <img src={token.imageUri} alt={token.name} className="w-6 h-6 rounded-full" />}
          <a href={`https://photon-sol.tinyastro.io/en/lp/${token.mint}`} target="_blank">
            {token.mint.slice(0, 6)}...{token.mint.slice(-6)}
          </a>
        </div>
      );
    },
  },
  {
    accessorKey: "name",
    header: "Name",
    cell: ({ row }) => (
      <div>
        {row.original.name} ({row.original.symbol})
      </div>
    ),
  },
  {
    accessorKey: "volume",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Volume ({selectedInterval / 60}h)
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => <div>${formatLargeNumber(Number(row.original.volume))}</div>,
  },
  {
    accessorKey: "marketCap",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Market Cap
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => (
      <div>{row.original.marketCap ? `$${formatLargeNumber(Number(row.original.marketCap))}` : "N/A"}</div>
    ),
  },
  {
    accessorKey: "liquidity",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Liquidity
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => <div>${formatLargeNumber(Number(row.original.liquidity))}</div>,
  },
  {
    accessorKey: "transactions",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Transactions ({selectedInterval / 60}h)
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => <div>{formatLargeNumber(row.original.transactions[selectedInterval])}</div>,
  },
  {
    accessorKey: "priceChange",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Price Change ({selectedInterval / 60}h)
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => {
      const change = row.original.priceChange[selectedInterval];
      return (
        <div className={change >= 0 ? "text-green-500" : "text-red-500"}>
          {change >= 0 ? "+" : ""}
          {(change * 100).toFixed(2)}%
        </div>
      );
    },
  },
  {
    accessorKey: "uniqueBuys",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Unique Buys ({selectedInterval / 60}h)
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => <div>{formatLargeNumber(row.original.uniqueBuys[selectedInterval])}</div>,
  },
  {
    accessorKey: "uniqueSells",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Unique Sells ({selectedInterval / 60}h)
        <Button
          className="w-7 h-7 p-0"
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          {column.getIsSorted() ? (
            column.getIsSorted() === "asc" ? (
              <ArrowUp className="size-4" />
            ) : (
              <ArrowDown className="size-4" />
            )
          ) : (
            <ArrowUpDown className="size-4" />
          )}
        </Button>
      </div>
    ),
    cell: ({ row }) => <div>{formatLargeNumber(row.original.uniqueSells[selectedInterval])}</div>,
  },
];
