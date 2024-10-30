import { formatDistance } from "date-fns";

import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useDataAnalysisData } from "@/hooks/use-data-analysis";

// Total average performance after the period has ended
// Average performance per interval during the period, using the same chart as the analytics
export const PerformanceBasePeriodDataTable = () => {
  const { data } = useDataAnalysisData();
  const { from, to } = useAnalyticsParams();
  console.log(data);

  return null;
  return (
    <Table className="text-left w-full">
      <TableCaption>
        Tokens performance over a period of {formatDistance(from, to)} after being selected using the specified
        parameters.
      </TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[100px]">Category</TableHead>
          <TableHead>Total</TableHead>
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
