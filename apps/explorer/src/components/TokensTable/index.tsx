import { useMemo } from "react";

import { columns } from "@/components/TokensTable/columns";
import { DataTable } from "@/components/ui/data-table";
import { useTokens } from "@/hooks/useTokens";
import { useTrackerParams } from "@/hooks/useTrackerParams";
import { formatTime } from "@/lib/utils";

export const TokensTable = () => {
  const { tokens, fetching, error } = useTokens();
  const { timespan, increasePct, minTrades } = useTrackerParams();

  const filteredTokens = useMemo(
    () => tokens.filter((token) => token.increasePct >= increasePct && token.trades >= minTrades),
    [tokens, increasePct, minTrades],
  );

  const tokensPerPlatform = useMemo(() => {
    return Object.entries(
      filteredTokens.reduce(
        (acc, token) => {
          acc[token.platform || "N/A"] = (acc[token.platform || "N/A"] || 0) + 1;
          return acc;
        },
        {} as Record<string, number>,
      ),
    ).sort((a, b) => b[1] - a[1]);
  }, [filteredTokens]);

  if (error) return <div>Error: {error}</div>;
  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <div className="text-end font-bold">Total coins: {filteredTokens.length}</div>
      {Object.entries(tokensPerPlatform).length > 0 && (
        <div className="flex gap-4 flex-wrap justify-end">
          <span>Platforms: </span>
          {Object.entries(tokensPerPlatform).map(([, [platform, count]]) => (
            <div key={platform} className="opacity-50">
              {platform.charAt(0).toUpperCase() + platform.slice(1)}: {count}
            </div>
          ))}
        </div>
      )}
      <DataTable
        columns={columns}
        data={filteredTokens}
        caption={`List of tokens pumping at least ${increasePct}% in the last ${formatTime(timespan)} with at least ${minTrades} trades`}
        loading={fetching && tokens.length === 0}
        pagination={true}
        defaultSorting={[{ id: "increasePct", desc: true }]}
      />
    </div>
  );
};
