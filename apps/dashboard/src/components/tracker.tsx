import { useState } from "react";

import { TokenChart } from "@/components/token-chart";
import { TokensTable } from "@/components/tokens-table";
import { Interval, Token } from "@/lib/types";

export const Tracker = () => {
  const [selectedToken, setSelectedToken] = useState<Token | null>(null);
  const [selectedInterval, setSelectedInterval] = useState<Interval>("30m");

  if (selectedToken)
    return (
      <TokenChart token={selectedToken} selectedInterval={selectedInterval} onBack={() => setSelectedToken(null)} />
    );
  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4 p-4">
      <h3 className="text-lg font-semibold">Pumping tokens</h3>
      <TokensTable
        onRowClick={(row) => setSelectedToken(row.original as Token)}
        selectedInterval={selectedInterval}
        setSelectedInterval={setSelectedInterval}
      />
    </div>
  );
};
