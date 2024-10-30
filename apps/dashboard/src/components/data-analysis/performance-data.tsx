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
};
