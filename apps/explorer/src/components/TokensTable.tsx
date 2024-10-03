import { useCallback, useEffect, useMemo, useState } from "react";

import { PRICE_PRECISION } from "@tub/indexer/constants";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Token, useTokens } from "@/hooks/useTokens";
import { useTrackerParams } from "@/hooks/useTrackerParams";
import { formatTime } from "@/lib/utils";

export const TokensTable = () => {
  const { tokens, fetching, error } = useTokens();
  const { timespan, increasePct, minTrades } = useTrackerParams();
  const [data, setData] = useState<Token[]>([]);
  const [sortBy, setSortBy] = useState<"increase" | "price" | "trades">("increase");

  const filterAndSortTokens = useCallback(() => {
    return tokens
      .filter((token) => token.increasePct >= increasePct && token.trades >= minTrades)
      .sort((a, b) => {
        if (sortBy === "price") {
          return b.latestPrice - a.latestPrice;
        } else if (sortBy === "trades") {
          return b.trades - a.trades;
        } else {
          return b.increasePct - a.increasePct;
        }
      });
  }, [tokens, increasePct, minTrades, sortBy]);

  useEffect(() => {
    setData(filterAndSortTokens());
  }, [filterAndSortTokens]);

  if (error) return <div>Error: {error}</div>;
  if (fetching && tokens.length === 0) return <div>Loading...</div>;
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
          <TableRow className="text-end">
            <TableCell colSpan={3} className="text-end">
              Sort by
            </TableCell>
            <TableCell>
              <Select
                defaultValue="increase"
                onValueChange={(value) => setSortBy(value as "increase" | "price" | "trades")}
              >
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Sort by" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="increase">Price increase</SelectItem>
                  <SelectItem value="price">Current price</SelectItem>
                  <SelectItem value="trades">Trades</SelectItem>
                </SelectContent>
              </Select>
            </TableCell>
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
          {data.map((token) => (
            <TableRow key={token.mint}>
              <TableCell className="font-medium">{token.mint}</TableCell>
              <TableCell>{token.trades}</TableCell>
              <TableCell>{(token.latestPrice / PRICE_PRECISION).toFixed(9)}</TableCell>
              <TableCell className="text-right">{token.increasePct.toFixed(2)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
};
