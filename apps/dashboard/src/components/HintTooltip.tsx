import { ReactNode } from "react";
import { Info } from "lucide-react";

import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

export const HintTooltip = ({ content, className }: { content: ReactNode | string; className?: string }) => {
  return (
    <Tooltip>
      <TooltipTrigger
        className={cn(
          "absolute -left-[34px] 2xl:-left-20 top-1/2 -translate-y-1/2 p-1.5 opacity-70 hover:opacity-100",
          className,
        )}
      >
        <Info className="w-4 h-4" />
      </TooltipTrigger>
      <TooltipContent>{content}</TooltipContent>
    </Tooltip>
  );
};
