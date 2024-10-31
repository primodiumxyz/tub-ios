import { formatDistance } from "date-fns";

import { DatePresetsPicker, DateRangePicker } from "@/components/analytics/date-picker";
import { useAnalyticsData } from "@/hooks/use-analytics";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";

import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "../ui/table";

// Select one day: total + each hour (total + avg per second)
// Select multiple days: total + each day (total + avg per second)
export const Analytics = () => {
  const { swaps, totalSwaps, newTokens, totalNewTokens, error } = useAnalyticsData();
  const { from, to } = useAnalyticsParams();

  if (error) return <div>{error}</div>;
  return (
    <div className="flex flex-col items-start w-full max-h-fit">
      <h3 className="text-lg font-semibold">Analytics</h3>
      <div className="flex gap-2">
        <DateRangePicker />
        <DatePresetsPicker />
      </div>
      <Table className="text-left w-full">
        <TableCaption>Swaps and new tokens over a period of {formatDistance(from, to)}.</TableCaption>
        <TableHeader>
          <TableRow>
            <TableHead className="w-[100px]">Category</TableHead>
            <TableHead>Total</TableHead>
            {swaps?.map((swap) => (
              <TableHead>
                {swaps.indexOf(swap) === 0 ||
                new Date(swap.hour ?? "").getDay() !== new Date(swaps[swaps.indexOf(swap) - 1].hour ?? "").getDay()
                  ? new Date(swap.hour ?? "").toLocaleString()
                  : new Date(swap.hour ?? "").toLocaleTimeString()}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow>
            <TableCell className="font-medium">Swaps</TableCell>
            <TableCell>
              {totalSwaps?.toLocaleString()}{" "}
              <span className="text-muted-foreground">
                {totalSwaps ? (totalSwaps / (3600 * (swaps?.length ?? 1))).toLocaleString() : 0}/s
              </span>
            </TableCell>
            {swaps?.map((swap) => (
              <TableCell>
                {swap.count?.toLocaleString()}{" "}
                <span className="text-muted-foreground">
                  {swap.count ? (Number(swap.count) / 3600).toLocaleString() : 0}/s
                </span>
              </TableCell>
            ))}
          </TableRow>
          <TableRow>
            <TableCell className="font-medium">New tokens</TableCell>
            <TableCell>
              {totalNewTokens?.toLocaleString()}{" "}
              <span className="text-muted-foreground">
                {totalNewTokens ? (totalNewTokens / (3600 * (newTokens?.length ?? 1))).toLocaleString() : 0}/s
              </span>
            </TableCell>
            {newTokens?.map((newToken) => (
              <TableCell>
                {newToken.count?.toLocaleString()}{" "}
                <span className="text-muted-foreground">
                  {newToken.count ? (Number(newToken.count) / 3600).toLocaleString() : 0}/s
                </span>
              </TableCell>
            ))}
          </TableRow>
        </TableBody>
      </Table>
    </div>
  );
};
