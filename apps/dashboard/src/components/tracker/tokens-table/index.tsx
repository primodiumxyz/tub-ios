import { useEffect, useMemo, useState } from "react";

import { getColumns } from "@/components/tracker/tokens-table/columns";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/ui/data-table";
import { Input } from "@/components/ui/input";
import { useSolPrice } from "@/hooks/use-sol-price";
import { Token, useTokens } from "@/hooks/use-tokens";
import { useTrackerParams } from "@/hooks/use-tracker-params";

export const TokensTable = () => {
  const { tokens, fetching, error } = useTokens();
  const { timespan, minTrades, minVolume } = useTrackerParams();
  const { solToUsd } = useSolPrice();
  const [globalFilter, setGlobalFilter] = useState<string>("");
  const [frozen, setFrozen] = useState(false);
  const [frozenTokens, setFrozenTokens] = useState<Token[]>([]);

  useEffect(() => {
    if (frozen) setFrozenTokens(tokens);
  }, [frozen]);

  const filteredTokens = useMemo(() => {
    const tokenArray = frozen ? frozenTokens : tokens;
    if (globalFilter === "") return tokenArray;
    return tokenArray.filter(
      (token) =>
        token.name.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.symbol.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.mint.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.id.toLowerCase().includes(globalFilter.toLowerCase()),
    );
  }, [tokens, frozenTokens, frozen, globalFilter]);

  if (error) return <div>Error: {error}</div>;
  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <div className="flex items-center justify-between gap-4">
        <div className="flex gap-2 items-center">
          <div className="flex items-center gap-2">
            <Button onClick={() => setFrozen(!frozen)} variant={frozen ? "destructive" : "ghost"}>
              {frozen ? "Unfreeze" : "Freeze"}
            </Button>
          </div>
          <span className="text-sm text-muted-foreground">
            {tokens.length} tokens {frozen && `(frozen at ${frozenTokens.length})`}
          </span>
        </div>
        <Input
          placeholder="Search"
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      <DataTable
        columns={getColumns(solToUsd)}
        data={filteredTokens}
        caption={`List of tokens with at least ${minVolume} volume and at least ${minTrades} trades in the last ${timespan}`}
        loading={fetching}
        pagination={true}
        defaultSorting={[{ id: "increasePct", desc: true }]}
      />
    </div>
  );
};
