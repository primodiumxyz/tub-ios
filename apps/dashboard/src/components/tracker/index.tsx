import { TokensTable } from "@/components/tracker/tokens-table";
import { TrackerParams } from "@/components/tracker/tracker-params";

export const Tracker = () => {
  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4">
      <h3 className="text-lg font-semibold">Pumping tokens</h3>
      <TrackerParams />
      <TokensTable />
    </div>
  );
};
