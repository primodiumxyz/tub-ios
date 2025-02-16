import { useEffect, useState } from "react";
import { Row } from "@tanstack/react-table";

import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/ui/data-table";
import { Input } from "@/components/ui/input";
import { useTrades } from "@/hooks/use-trades";
import { GroupedTrade } from "@/lib/types";

import { columns } from "./columns";

/**
 * Component to display the trades table
 *
 * @param onRowClick - The callback to call when a row is clicked
 * @returns The trades table component
 */
export const TradesTable = ({ onRowClick }: { onRowClick?: (row: Row<GroupedTrade>) => void }) => {
  const [globalFilter, setGlobalFilter] = useState<string>("");
  const [frozen, setFrozen] = useState(false);
  const [frozenTrades, setFrozenTrades] = useState<GroupedTrade[]>([]);

  const { trades, fetching, error } = useTrades({
    limit: 1000,
    userWalletOrTokenMint: globalFilter || undefined,
  });

  useEffect(() => {
    if (frozen) setFrozenTrades(trades);
  }, [frozen]);

  if (error) return <div>Error: {error}</div>;

  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <h3 className="text-lg font-medium text-left">Latest trades</h3>
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <Button onClick={() => setFrozen(!frozen)} variant={frozen ? "destructive" : "ghost"}>
            {frozen ? "Unfreeze" : "Freeze"}
          </Button>
        </div>
        <span className="text-sm text-muted-foreground">
          {trades.length} trades {frozen && `(frozen at ${frozenTrades.length})`}
        </span>
        <span className="grow" />
        <Input
          placeholder="Search user wallet or token mint..."
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      <DataTable
        columns={columns}
        data={frozen ? frozenTrades : trades}
        loading={fetching}
        onRowClick={onRowClick}
        defaultSorting={[{ id: "sellInfo", desc: true }]}
        pagination={true}
      />
    </div>
  );
};
