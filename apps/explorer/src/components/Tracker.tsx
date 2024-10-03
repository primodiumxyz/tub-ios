import { TokensTable } from "@/components/TokensTable";
import { TrackerParams } from "@/components/TrackerParams";
import { useTokens } from "@/hooks/useTokens";

export const Tracker = () => {
  const { tokens } = useTokens();

  return (
    <div className="flex flex-col items-start w-full max-h-fit">
      <TrackerParams />
      <TokensTable data={tokens} />
    </div>
  );
};
