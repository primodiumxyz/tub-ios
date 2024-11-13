import { ColumnDef } from "@tanstack/react-table";
import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Token } from "@/hooks/use-tokens";
import { formatLargeNumber } from "@/lib/utils";

export const getColumns = (solToUsd: (solAmount: number) => string): ColumnDef<Token>[] => [
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
    accessorKey: "volume",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Volume
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
      return (
        <div className="flex flex-col gap-1">
          <span>{solToUsd(row.original.volume)}</span>
          <span className="text-xs text-muted-foreground">({formatLargeNumber(row.original.volume)} SOL)</span>
        </div>
      );
    },
  },
  {
    accessorKey: "latestPrice",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Price
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
      return (
        <div className="flex flex-col gap-1">
          <span>{solToUsd(row.original.latestPrice)}</span>
          <span className="text-xs text-muted-foreground">({row.original.latestPrice.toFixed(9)} SOL)</span>
        </div>
      );
    },
  },
  {
    accessorKey: "increasePct",
    header: ({ column }) => {
      return (
        <div className="flex items-center gap-2">
          Price change (%)
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
  {
    accessorKey: "mintBurnt",
    header: "Mint Burnt",
    cell: ({ row }) => {
      return <div>{row.original.mintBurnt ? "Yes" : "No"}</div>;
    },
  },
  {
    accessorKey: "freezeBurnt",
    header: "Freeze Burnt",
    cell: ({ row }) => {
      return <div>{row.original.freezeBurnt ? "Yes" : "No"}</div>;
    },
  },
];
