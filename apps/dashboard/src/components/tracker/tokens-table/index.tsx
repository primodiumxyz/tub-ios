import { useMemo, useState } from "react";

import { columns } from "@/components/tracker/tokens-table/columns";
import { DataTable } from "@/components/ui/data-table";
import { Input } from "@/components/ui/input";
import { useTokens } from "@/hooks/use-tokens";
import { useTrackerParams } from "@/hooks/use-tracker-params";

export const TokensTable = () => {
  const { tokens, fetching, error } = useTokens();
  const { timespan, increasePct, minTrades } = useTrackerParams();
  const [globalFilter, setGlobalFilter] = useState<string>("");

  const filteredTokens = useMemo(() => {
    if (globalFilter === "") return tokens;
    return tokens.filter(
      (token) =>
        token.name.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.symbol.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.mint.toLowerCase().includes(globalFilter.toLowerCase()) ||
        token.id.toLowerCase().includes(globalFilter.toLowerCase()),
    );
  }, [tokens, globalFilter]);

  if (error) return <div>Error: {error}</div>;
  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground">{tokens.length} tokens</span>
        <Input
          placeholder="Search"
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      <DataTable
        columns={columns}
        data={filteredTokens}
        caption={`List of tokens pumping at least ${increasePct}% in the last ${timespan} with at least ${minTrades} trades`}
        loading={fetching}
        pagination={true}
        defaultSorting={[{ id: "increasePct", desc: true }]}
      />
    </div>
  );
};
