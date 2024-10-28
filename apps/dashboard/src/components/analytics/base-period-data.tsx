import { formatDistance } from "date-fns";

import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAnalyticsData } from "@/hooks/use-analytics";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";

export const BasePeriodDataTable = () => {
  const { swaps, totalSwaps, newTokens, totalNewTokens, error } = useAnalyticsData();
  const { from, to } = useAnalyticsParams();

  if (error) return <div>{error}</div>;
  return (
    <Table className="text-left w-full">
      <TableCaption>Swaps and new tokens over a period of {formatDistance(from, to)}.</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[100px]">Category</TableHead>
          <TableHead>Total</TableHead>
          {swaps?.map((swap, i) => (
            <TableHead key={i} className="h-full">
              <div className="flex flex-col">
                {i === 0 ||
                new Date(swap.hour ?? "").getDay() !== new Date(swaps[swaps.indexOf(swap) - 1].hour ?? "").getDay() ? (
                  <span>{new Date(swap.hour ?? "").toLocaleDateString()}</span>
                ) : (
                  <span className="opacity-0">-</span>
                )}
                <span>{new Date(swap.hour ?? "").toLocaleTimeString()}</span>
              </div>
            </TableHead>
          ))}
        </TableRow>
      </TableHeader>
      <TableBody>
        <TableRow>
          <TableCell className="font-medium">Swaps</TableCell>
          <TableCell className="flex flex-col">
            {totalSwaps?.toLocaleString()}
            <span className="text-muted-foreground">
              {totalSwaps ? (totalSwaps / (3600 * (swaps?.length ?? 1))).toLocaleString() : 0}/s
            </span>
          </TableCell>
          {swaps?.map((swap, i) => (
            <TableCell key={i}>
              <div className="flex flex-col">
                {swap.count?.toLocaleString()}
                <span className="text-muted-foreground">
                  {swap.count ? (Number(swap.count) / 3600).toLocaleString() : 0}/s
                </span>
              </div>
            </TableCell>
          ))}
        </TableRow>
        <TableRow>
          <TableCell className="font-medium">New tokens</TableCell>
          <TableCell className="flex flex-col">
            {totalNewTokens?.toLocaleString()}
            <span className="text-muted-foreground">
              {totalNewTokens ? (totalNewTokens / (3600 * (newTokens?.length ?? 1))).toLocaleString() : 0}/s
            </span>
          </TableCell>
          {newTokens?.map((newToken, i) => (
            <TableCell key={i}>
              <div className="flex flex-col">
                {newToken.count?.toLocaleString()}{" "}
                <span className="text-muted-foreground">
                  {newToken.count ? (Number(newToken.count) / 3600).toLocaleString() : 0}/s
                </span>
              </div>
            </TableCell>
          ))}
        </TableRow>
      </TableBody>
    </Table>
  );
};
