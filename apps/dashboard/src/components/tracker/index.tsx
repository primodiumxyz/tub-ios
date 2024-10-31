import { TokensTable } from "@/components/tracker/tokens-table";
import { TrackerParams } from "@/components/tracker/tracker-params";

export const Tracker = () => {
  return (
    <div className="flex flex-col items-start w-full max-h-fit">
      <TrackerParams />
      <TokensTable />
    </div>
  );
};
