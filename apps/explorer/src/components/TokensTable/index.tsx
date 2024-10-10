import { useMemo, useState } from "react";

import { columns } from "@/components/TokensTable/columns";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/ui/data-table";
import { useTokens } from "@/hooks/useTokens";
import { useTrackerParams } from "@/hooks/useTrackerParams";
import { formatTime } from "@/lib/utils";

export const TokensTable = () => {
  const { tokens, fetching, error } = useTokens();
  const { timespan, increasePct, minTrades } = useTrackerParams();
  const [platformFilter, setPlatformFilter] = useState<string>("");

  const tokensPerPlatform = useMemo(() => {
    return Object.entries(
      tokens.reduce(
        (acc, token) => {
          acc[token.platform || "N/A"] = (acc[token.platform || "N/A"] || 0) + 1;
          return acc;
        },
        {} as Record<string, number>,
      ),
    ).sort((a, b) => b[1] - a[1]);
  }, [tokens]);

  const filteredTokens = useMemo(() => {
    if (platformFilter === "") return tokens;
    return tokens.filter((token) => token.platform === platformFilter);
  }, [tokens, platformFilter]);

  if (error) return <div>Error: {error}</div>;
  return (
    <div className="flex flex-col gap-2 mt-2 w-full">
      <div className="flex gap-2 flex-wrap justify-end">
        {Object.entries(tokensPerPlatform).length > 0 && (
          <>
            {Object.entries(tokensPerPlatform).map(([, [platform, count]]) => (
              <Button
                key={platform}
                variant={platformFilter === platform ? "secondary" : "ghost"}
                onClick={() => setPlatformFilter(platform)}
              >
                {platform}: {count}
              </Button>
            ))}
          </>
        )}
        <Button variant={platformFilter === "" ? "secondary" : "ghost"} onClick={() => setPlatformFilter("")}>
          All ({tokens.length})
        </Button>
      </div>
      <DataTable
        columns={columns}
        data={filteredTokens}
        caption={`List of tokens pumping at least ${increasePct}% in the last ${formatTime(timespan)} with at least ${minTrades} trades`}
        loading={fetching}
        pagination={true}
        defaultSorting={[{ id: "increasePct", desc: true }]}
      />
    </div>
  );
};
