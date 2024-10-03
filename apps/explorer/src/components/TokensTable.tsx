import { FC, useMemo, useState } from "react";

import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { PumpingToken } from "@/hooks/usePumpingTokens";
import { useTrackerParams } from "@/hooks/useTrackerParams";
import { formatTime } from "@/lib/utils";

export const TokensTable: FC<{ data: PumpingToken[] }> = ({ data }) => {
  const { timespan, increasePct, minTrades } = useTrackerParams();
  const [sortBy, setSortBy] = useState<"increase" | "price" | "trades">("increase");

  const sortedData = useMemo(() => {
    return data.sort((a, b) => {
      if (sortBy === "price") {
        return b.latestPrice - a.latestPrice;
      } else if (sortBy === "trades") {
        return b.trades - a.trades;
      } else {
        return b.increasePct - a.increasePct;
      }
    });
  }, [data, sortBy]);

  return (
    <div className="w-full h-fit overflow-y-auto">
      <Table className="w-full">
        <TableCaption>
          List of tokens pumping at least {increasePct}% in the last {formatTime(timespan)} with at least {minTrades}{" "}
          trades
        </TableCaption>
        <TableHeader>
          <TableRow className="text-start font-bold">
            <TableCell colSpan={3}>Total coins</TableCell>
            <TableCell className="text-right">{data.length}</TableCell>
          </TableRow>
        </TableHeader>
        <TableHeader>
          <TableRow>
            <TableHead className="w-60">Token</TableHead>
            <TableHead className="w-20">Trades</TableHead>
            <TableHead className="w-40">Current price (SOL)</TableHead>
            <TableHead className="text-right">Price increase (%)</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody className="text-start">
          {sortedData.map((token) => (
            <TableRow key={token.mint}>
              <TableCell className="font-medium">{token.mint}</TableCell>
              <TableCell>{token.trades}</TableCell>
              <TableCell>{token.latestPrice.toLocaleString()}</TableCell>
              <TableCell className="text-right">{token.increasePct.toFixed(2)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
};
