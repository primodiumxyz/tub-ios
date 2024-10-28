import { formatDistance } from "date-fns";

import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useAnalyticsData } from "@/hooks/use-analytics";
import { useAnalyticsParams } from "@/hooks/use-analytics-params";
import { useTrackerParams } from "@/hooks/use-tracker-params";

import { FilteredTokensChart } from "./filtered-tokens-period-chart";

export const FilteredTokensPeriodDataTable = () => {
  const { from, to } = useAnalyticsParams();
  const { filteredTokensPerInterval } = useAnalyticsData();

  //   if (error) return <div>{error}</div>;
  // TODO: table need to be inverted, one row per category
  if (filteredTokensPerInterval.data)
    return <FilteredTokensChart data={filteredTokensPerInterval.data} width={1200} height={400} />;
};
