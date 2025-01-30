import { ColumnDef } from "@tanstack/react-table";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Token } from "@/lib/types";
import { formatLargeNumber } from "@/lib/utils";

/**
 * Function to get the columns for the tokens table
 *
 * @param selectedInterval - The interval to display the data for
 * @returns The columns for the tokens table {@link ColumnDef<Token>[]}
 */
export const getColumns = (selectedInterval = "30m"): ColumnDef<Token>[] => [
  /* ---------------------------------- mint ---------------------------------- */
  {
    accessorKey: "mint",
    header: "Token",
    cell: ({ row }) => {
      const token = row.original;
      return (
        <div className="flex items-center gap-2">
          {token.imageUri && <img src={token.imageUri} alt={token.name} className="w-6 h-6 rounded-full" />}
          <a
            href={`https://photon-sol.tinyastro.io/en/lp/${token.mint}`}
            target="_blank"
            onClick={(e) => e.stopPropagation()}
          >
            {token.mint?.slice(0, 6)}...{token.mint?.slice(-6)}
          </a>
        </div>
      );
    },
  },
  /* ---------------------------------- name ---------------------------------- */
  {
    accessorKey: "name",
    header: "Name",
    cell: ({ row }) => (
      <div>
        {row.original.name} ({row.original.symbol})
      </div>
    ),
  },
  /* --------------------------------- volume --------------------------------- */
  {
    accessorKey: "volume",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Volume ({selectedInterval})
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
    cell: ({ row }) => <div>${formatLargeNumber(row.original.volumeUsd)}</div>,
  },
  /* ------------------------------ transactions ------------------------------ */
  {
    accessorKey: "transactions",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Transactions ({selectedInterval})
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
    cell: ({ row }) => <div>{formatLargeNumber(row.original.tradeCount)}</div>,
  },
  /* ------------------------------ price change ------------------------------ */
  {
    accessorKey: "priceChange",
    header: ({ column }) => (
      <div className="flex items-center gap-2">
        Price Change ({selectedInterval})
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
      const change = row.original.priceChangePct;
      return (
        <div className={change >= 0 ? "text-green-500" : "text-red-500"}>
          {change >= 0 ? "+" : ""}
          {change.toFixed(2)}%
        </div>
      );
    },
  },
];
