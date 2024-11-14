import { TokensTable } from "@/components/tracker/tokens-table";

export const Tracker = () => {
  return (
    <div className="flex flex-col items-start w-full max-h-fit gap-4 p-4">
      <h3 className="text-lg font-semibold">Pumping tokens</h3>
      <TokensTable />
    </div>
  );
};
