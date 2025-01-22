import { useEffect, useState } from "react";
import { Row } from "@tanstack/react-table";

import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/ui/data-table";
import { Input } from "@/components/ui/input";
import { useTrades } from "@/hooks/use-trades";
import { GroupedTrade, TradeFilters } from "@/lib/types";

import { columns } from "./columns";

export const TradesTable = ({ onRowClick }: { onRowClick?: (row: Row<GroupedTrade>) => void }) => {
  const [globalFilter, setGlobalFilter] = useState<string>("");
  const [frozen, setFrozen] = useState(false);
  const [frozenTrades, setFrozenTrades] = useState<GroupedTrade[]>([]);

  // TODO: filters
  const filters: TradeFilters = {
    userWallet: undefined,
    tokenMint: undefined,
    status: undefined,
    limit: 100,
  };
  const { trades, fetching, error } = useTrades(filters);

  useEffect(() => {
    if (frozen) setFrozenTrades(trades);
  }, [frozen]);

  // Filter trades based on global search
  const filteredTrades = (frozen ? frozenTrades : trades).filter((trade) => {
    if (!globalFilter) return true;
    const searchTerm = globalFilter.toLowerCase();
    return trade.token.toLowerCase().includes(searchTerm) || trade.userWallet.toLowerCase().includes(searchTerm);
  });

  if (error) return <div>Error: {error}</div>;

  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <Button onClick={() => setFrozen(!frozen)} variant={frozen ? "destructive" : "ghost"}>
            {frozen ? "Unfreeze" : "Freeze"}
          </Button>
        </div>
        <span className="text-sm text-muted-foreground">
          {filteredTrades.length} trades {frozen && `(frozen at ${frozenTrades.length})`}
        </span>
        <span className="grow" />
        <Input
          placeholder="Search tokens..."
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      <DataTable
        columns={columns}
        data={filteredTrades}
        loading={fetching}
        onRowClick={onRowClick}
        defaultSorting={[{ id: "sellInfo", desc: true }]}
        pagination={true}
      />
    </div>
  );
};
