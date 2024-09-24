import { useEffect, useRef } from "react";
import * as d3 from "d3";

type Price = {
  timestamp: number;
  price: number;
};

type PriceGraphProps = {
  prices: Price[];
};

export const PriceGraph = ({ prices }: PriceGraphProps) => {
  const svgRef = useRef<SVGSVGElement | null>(null);

  useEffect(() => {
    if (prices.length === 0) return;

    const svg = d3.select(svgRef.current);
    const width = 600;
    const height = 500;
    const margin = { top: 20, right: 30, bottom: 50, left: 60 }; // Adjusted margins for labels

    const x = d3
      .scaleTime()
      .domain(d3.extent(prices, (d) => new Date(d.timestamp)) as [Date, Date])
      .range([margin.left, width - margin.right]);

    const y = d3
      .scaleLinear()
      .domain([0, d3.max(prices, (d) => d.price) as number])
      .nice()
      .range([height - margin.bottom, margin.top]);

    const line = d3
      .line<Price>()
      .x((d) => x(new Date(d.timestamp)))
      .y((d) => y(d.price))
      .curve(d3.curveMonotoneX);

    svg.selectAll("*").remove();

    svg
      .append("g")
      .attr("transform", `translate(0,${height - margin.bottom})`)
      .call(
        d3
          .axisBottom(x)
          .ticks(width / 80)
          .tickSizeOuter(0)
      )
      .append("text")
      .attr("fill", "#000")
      .attr("x", width / 2)
      .attr("y", margin.bottom - 10)
      .attr("text-anchor", "middle")
      .text("Time");

    svg
      .append("g")
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y).tickFormat(d => `$${d}`)) // Format y-axis labels with dollar sign
      .append("text")
      .attr("fill", "#000")
      .attr("transform", "rotate(-90)")
      .attr("x", -height / 2)
      .attr("y", -margin.left + 20)
      .attr("text-anchor", "middle")
      .text("Price");

    svg
      .append("path")
      .datum(prices)
      .attr("fill", "none")
      .attr("stroke", "steelblue")
      .attr("stroke-width", 1.5)
      .attr("d", line);
  }, [prices]);

  return (
    <div className="bg-white shadow-lg rounded-lg p-4">
      <h2 className="text-xl font-semibold mb-4">Price Graph</h2>
      <svg ref={svgRef} width={600} height={500}></svg>
    </div>
  );
};