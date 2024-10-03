import { TokensTable } from "@/components/TokensTable";
import { TrackerParams } from "@/components/TrackerParams";
import { usePumpingTokens } from "@/hooks/usePumpingTokens";

export const Tracker = () => {
  const { pumpingTokens } = usePumpingTokens();

  return (
    <div className="flex flex-col items-start w-full max-h-fit">
      <TrackerParams />
      <TokensTable data={pumpingTokens} />
    </div>
  );
};
