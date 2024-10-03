import { TokensTable } from "@/components/TokensTable";
import { TrackerParams } from "@/components/TrackerParams";

export const Tracker = () => {
  return (
    <div className="flex flex-col items-start w-full max-h-fit">
      <TrackerParams />
      <TokensTable />
    </div>
  );
};
