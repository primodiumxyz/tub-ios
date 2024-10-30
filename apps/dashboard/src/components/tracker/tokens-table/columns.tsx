import { ColumnDef } from "@tanstack/react-table";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Token } from "@/hooks/use-tokens";
import { PRICE_PRECISION } from "@/lib/constants";

export const columns: ColumnDef<Token>[] = [
  {
    accessorKey: "mint",
    header: "Token",
    cell: ({ row }) => {
      return (
        <a href={`https://photon-sol.tinyastro.io/en/lp/${row.original.mint}`} target="_blank">
          {row.original.mint.slice(0, 6)}...{row.original.mint.slice(-6)}
        </a>
      );
    },
  },
  {
    accessorKey: "name",
    header: "Name",
    cell: ({ row }) => {
      return (
        <div>
          {row.original.name} ({row.original.symbol})
        </div>
      );
    },
  },
  {
    accessorKey: "platform",
    header: "Platform",
    cell: ({ row }) => {
      if (row.original.platform === "") return <span className="opacity-50">N/A</span>;
      return <div>{row.original.platform}</div>;
    },
  },
  {
    accessorKey: "trades",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Trades
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
      );
    },
  },
  {
    accessorKey: "latestPrice",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Price (SOL)
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
      );
    },
    cell: ({ row }) => {
      return <div>{(row.original.latestPrice / PRICE_PRECISION).toFixed(9)}</div>;
    },
  },
  {
    accessorKey: "increasePct",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Price increase (%)
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
      );
    },
    cell: ({ row }) => {
      return <div>{Number(row.original.increasePct.toFixed(2))}</div>;
    },
  },
];
