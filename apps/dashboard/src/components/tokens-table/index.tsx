import { useEffect, useMemo, useState } from "react";
import { Row } from "@tanstack/react-table";

import { getColumns } from "@/components/tokens-table/columns";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/ui/data-table";
import { Input } from "@/components/ui/input";
import { useTokens } from "@/hooks/use-tokens";
import { INTERVALS } from "@/lib/constants";
import { Interval, Token } from "@/lib/types";

export const TokensTable = ({ onRowClick }: { onRowClick?: (row: Row<Token>) => void }) => {
  const [globalFilter, setGlobalFilter] = useState<string>("");
  const [frozen, setFrozen] = useState(false);
  const [frozenTokens, setFrozenTokens] = useState<Token[]>([]);
  const [selectedInterval, setSelectedInterval] = useState<Interval>("30m");

  const { tokens, fetching, error } = useTokens(selectedInterval);

  useEffect(() => {
    if (frozen) setFrozenTokens(tokens);
  }, [frozen]);

  const filteredTokens = useMemo(() => {
    const tokenArray = frozen ? frozenTokens : tokens;
    if (globalFilter === "") return tokenArray;
    return tokenArray.filter(
      (token) =>
        token.name?.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.symbol?.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.mint?.toLowerCase().includes(globalFilter.toLowerCase()),
    );
  }, [tokens, frozenTokens, frozen, globalFilter]);

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
          {tokens.length} tokens {frozen && `(frozen at ${frozenTokens.length})`}
        </span>
        <span className="grow" />
        <select
          value={selectedInterval}
          onChange={(e) => setSelectedInterval(e.target.value as Interval)}
          className="rounded-md border p-2"
        >
          {INTERVALS.map((interval) => (
            <option value={interval}>{interval}</option>
          ))}
        </select>
        <Input
          placeholder="Search"
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      <DataTable
        columns={getColumns(selectedInterval)}
        data={filteredTokens}
        caption={`List of the first 50 trending tokens by volume during the last ${selectedInterval}.`}
        loading={fetching}
        pagination={true}
        onRowClick={onRowClick}
      />
    </div>
  );
};
