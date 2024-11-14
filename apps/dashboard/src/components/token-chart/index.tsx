import { useState } from "react";
import { ArrowLeft, CandlestickChart, LineChart } from "lucide-react";

import { TradingViewCandlesChart } from "@/components/token-chart/tradingview-candles";
import { TradingViewChart } from "@/components/token-chart/tradingview-chart";
import { Button } from "@/components/ui/button";
import { Token } from "@/lib/types";
import { formatLargeNumber } from "@/lib/utils";

export const TokenChart = ({ token, onBack }: { token: Token; onBack: () => void }) => {
  const [chartType, setChartType] = useState<"line" | "candles">("line");

  return (
    <div className="flex flex-col w-full gap-4 p-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div className="flex items-center gap-2">
            {token.imageUri && <img src={token.imageUri} alt={token.name} className="w-6 h-6 rounded-full" />}
            <div>
              <h3 className="text-lg font-semibold">
                {token.name} (${token.symbol})
              </h3>
              <div className="flex gap-4 text-sm text-muted-foreground">
                <span>MC: ${formatLargeNumber(Number(token.marketCap ?? 0))}</span>
                <span>Vol: ${formatLargeNumber(Number(token.volume))}</span>
                <span>Liq: ${formatLargeNumber(Number(token.liquidity))}</span>
              </div>
            </div>
          </div>
        </div>
        <div className="flex gap-2">
          <Button
            variant={chartType === "line" ? "default" : "outline"}
            size="icon"
            onClick={() => setChartType("line")}
          >
            <LineChart className="h-4 w-4" />
          </Button>
          <Button
            variant={chartType === "candles" ? "default" : "outline"}
            size="icon"
            onClick={() => setChartType("candles")}
          >
            <CandlestickChart className="h-4 w-4" />
          </Button>
        </div>
      </div>
      {chartType === "line" ? <TradingViewChart token={token} /> : <TradingViewCandlesChart token={token} />}
    </div>
  );
};
