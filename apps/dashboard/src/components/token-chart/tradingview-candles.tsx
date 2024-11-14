import { useEffect, useRef } from "react";
import { CandlestickData, createChart, IChartApi, ISeriesApi, Time } from "lightweight-charts";

import { useTokenCandles } from "@/hooks/use-tokens-candles";
import { Token } from "@/lib/types";

export const TradingViewCandlesChart = ({ token }: { token: Token }) => {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const candleSeriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);

  const { tokenCandles, fetching, error } = useTokenCandles(token, (newCandle) => {
    if (!candleSeriesRef.current) return;

    // Convert the new candle data to the format expected by lightweight-charts
    const candleData: CandlestickData = {
      time: newCandle.t as Time,
      open: newCandle.o,
      high: newCandle.h,
      low: newCandle.l,
      close: newCandle.c,
    };

    // Update the last candle or add a new one
    candleSeriesRef.current.update(candleData);

    // Ensure the chart shows the latest data
    if (chartRef.current) {
      chartRef.current.timeScale().fitContent();
    }
  });

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
        rightOffset: 12,
        barSpacing: 12,
        fixLeftEdge: true,
        fixRightEdge: true,
        lockVisibleTimeRangeOnResize: true,
      },
      rightPriceScale: {
        borderVisible: false,
        autoScale: true,
      },
      leftPriceScale: {
        visible: false,
      },
    });

    // Create candlestick series
    const candleSeries = chart.addCandlestickSeries({
      upColor: "#26a69a",
      downColor: "#ef5350",
      borderVisible: false,
      wickUpColor: "#26a69a",
      wickDownColor: "#ef5350",
      priceFormat: {
        type: "price",
        precision: 6,
        minMove: 0.000001,
      },
    });
    candleSeriesRef.current = candleSeries;

    // Format data for the chart
    if (tokenCandles) {
      const chartData: CandlestickData[] = tokenCandles.t.map((t, i) => ({
        time: (t ?? 0) as Time,
        open: tokenCandles.o[i] ?? 0,
        high: tokenCandles.h[i] ?? 0,
        low: tokenCandles.l[i] ?? 0,
        close: tokenCandles.c[i] ?? 0,
      }));

      candleSeries.setData(chartData);

      // Set a fixed time range based on the data
      const firstTime = tokenCandles.t[0] ?? 0;
      const lastTime = tokenCandles.t[tokenCandles.t.length - 1] ?? 0;
      const timeRange = lastTime - firstTime;

      chart.timeScale().setVisibleRange({
        from: (firstTime - timeRange * 0.1) as Time, // Add 10% padding on the left
        to: (lastTime + timeRange * 0.02) as Time, // Add 2% padding on the right
      });
    }

    // Handle resize
    const handleResize = () => {
      if (chartContainerRef.current) {
        chart.applyOptions({
          width: chartContainerRef.current.clientWidth,
        });
        chart.timeScale().fitContent();
      }
    };

    window.addEventListener("resize", handleResize);
    chartRef.current = chart;

    return () => {
      window.removeEventListener("resize", handleResize);
      chart.remove();
    };
  }, [tokenCandles]);

  if (error) return <div>Error: {error}</div>;
  if (fetching && !tokenCandles) return <div>Loading...</div>;

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
