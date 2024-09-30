import * as d3 from "d3";
import { useEffect, useRef } from "react";

type Price = {
  timestamp: number;
  price: bigint;
};

type PriceGraphProps = {
  prices: Price[];
  buyPrice: bigint | undefined;
};

export const PriceGraph = ({ prices, buyPrice }: PriceGraphProps) => {
  const svgRef = useRef<SVGSVGElement | null>(null);
  const width = 300;
  const height = 200;
  useEffect(() => {
    if (prices.length === 0) return;

    const svg = d3.select(svgRef.current);

    const margin = { top: 25, right: 30, bottom: 20, left: 10 }; // Adjusted margins for labels

    const x = d3
      .scaleTime()
      .domain(d3.extent(prices, (d) => new Date(d.timestamp)) as [Date, Date])
      .range([margin.left, width - margin.right]);

    const y = d3
      .scaleLinear()
      .domain([0, d3.max(prices, (d) => Number(d.price)) as number])
      .nice()
      .range([height - margin.bottom, margin.top]);

    const line = d3
      .line<Price>()
      .x((d) => x(new Date(d.timestamp)))
      .y((d) => y(Number(d.price)))
      .curve(d3.curveMonotoneX);

    svg.selectAll("*").remove();

    svg
      .append("path")
      .datum(prices)
      .attr("fill", "none")
      .attr("stroke", "#6DF8FA")
      .attr("stroke-width", 1.5)
      .attr("d", line);

    // Add a circle at the end of the line
    const lastData = prices.length > 1 ? prices[prices.length - 1] : prices[0];
    const refPrice = buyPrice ?? prices[0].price;
    const lastX = x(new Date(lastData.timestamp));
    const lastY = y(Number(lastData.price));
    const pctChange = ((Number(lastData.price) - Number(refPrice)) / Number(refPrice)) * 100;
    const pctChangeColor = pctChange > 0 ? "lawngreen" : "#FF6666"; // Lighten the red color
    svg
      .append("line")
      .attr("x1", lastX)
      .attr("y1", margin.top)
      .attr("x2", lastX)
      .attr("y2", height - margin.bottom)
      .attr("stroke", pctChangeColor)
      .attr("stroke-width", 1)
      .attr("stroke-dasharray", "3,3");
    svg
      .append("circle")
      .attr("cx", lastX)
      .attr("cy", lastY)
      .attr("r", 4)
      .attr("fill", "none")
      .attr("stroke", pctChangeColor)
      .attr("stroke-width", 2);

    // Add a pill-shaped element with the current price
    const pillWidth = 40;
    const pillHeight = 24;
    const pillY = lastY - 30; // Position the pill above the circle

    svg
      .append("rect")
      .attr("x", lastX - pillWidth / 2)
      .attr("y", pillY)
      .attr("width", pillWidth)
      .attr("height", pillHeight)
      .attr("rx", pillHeight / 2) // Rounded corners
      .attr("ry", pillHeight / 2)
      .attr("fill", pctChangeColor)
      .attr("stroke-width", 1);

    svg
      .append("text")
      .attr("x", lastX)
      .attr("y", pillY + pillHeight / 2)
      .attr("text-anchor", "middle")
      .attr("dominant-baseline", "central")
      .attr("fill", "black")
      .attr("font-size", "12px")
      .text(`${pctChange.toFixed(0)}%`);
  }, [prices]);

  return (
    <div className="shadow-lg rounded-lg p-5">
      <svg ref={svgRef} width={width} height={height}></svg>
    </div>
  );
};
