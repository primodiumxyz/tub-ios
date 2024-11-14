import { useEffect, useRef } from "react";
import { createChart, IChartApi, ISeriesApi, LineData, Time } from "lightweight-charts";

import { useTokenPrices } from "@/hooks/use-token-prices";
import { Token } from "@/lib/types";

export const TradingViewChart = ({ token }: { token: Token }) => {
  const { tokenPrices, fetching, error } = useTokenPrices(token, 75, (newPrice) => {
    if (lineSeriesRef.current) {
      lineSeriesRef.current.update({
        time: newPrice.timestamp as Time,
        value: newPrice.price,
      });
    }
  });
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const lineSeriesRef = useRef<ISeriesApi<"Line"> | null>(null);

  useEffect(() => {
    if (!chartContainerRef.current) return;

    // Create chart
    const chart = createChart(chartContainerRef.current, {
      layout: {
        background: { color: "transparent" },
        textColor: "#d1d4dc",
      },
      grid: {
        vertLines: { visible: false },
        horzLines: { visible: false },
      },
      width: chartContainerRef.current.clientWidth,
      height: 400,
      timeScale: {
        timeVisible: true,
        secondsVisible: false,
        tickMarkFormatter: (time: number) => {
          const date = new Date(time * 1000);
          return date.toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
          });
        },
      },
      rightPriceScale: {
        borderVisible: false,
      },
      leftPriceScale: {
        visible: false,
      },
      crosshair: {
        horzLine: {
          visible: false,
          labelVisible: false,
        },
        vertLine: {
          visible: false,
          labelVisible: false,
        },
      },
      watermark: {
        visible: false,
      },
    });

    // Create line series
    const lineSeries = chart.addLineSeries({
      color: "#2962FF",
      lineWidth: 2,
    });
    lineSeriesRef.current = lineSeries;

    // Format data for the chart
    const chartData: LineData[] = tokenPrices.map((price) => ({
      time: price.timestamp as Time,
      value: price.price,
    }));

    lineSeries.setData(chartData);

    // Handle resize
    const handleResize = () => {
      if (chartContainerRef.current) {
        chart.applyOptions({
          width: chartContainerRef.current.clientWidth,
        });
      }
    };

    window.addEventListener("resize", handleResize);
    chartRef.current = chart;

    return () => {
      window.removeEventListener("resize", handleResize);
      chart.remove();
    };
  }, [tokenPrices]);

  // Update data when tokenPrices changes
  useEffect(() => {
    if (!chartRef.current || !lineSeriesRef.current || tokenPrices.length === 0) return;

    const chartData: LineData[] = tokenPrices.map((price) => ({
      time: price.timestamp as Time,
      value: price.price,
    }));

    lineSeriesRef.current.setData(chartData);

    // Optionally fit content
    chartRef.current.timeScale().fitContent();
  }, [tokenPrices]);

  if (error) return <div>Error: {error}</div>;
  if (fetching && !tokenPrices.length) return <div>Loading...</div>;

  return (
    <div>
      <div
        ref={chartContainerRef}
        style={{
          width: "100%",
          height: "400px",
        }}
      />
    </div>
  );
};
