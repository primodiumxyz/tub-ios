import React, { useMemo } from "react";
import { AxisBottom, AxisLeft } from "@visx/axis";
import { Group } from "@visx/group";
import { scaleBand, scaleLinear } from "@visx/scale";
import { Bar } from "@visx/shape";
import { defaultStyles, Tooltip, useTooltip } from "@visx/tooltip";
import { format } from "date-fns";

type DataPoint = {
  interval_start: Date;
  token_count: string;
};

type FilteredTokensChartProps = {
  data: DataPoint[];
  width: number;
  height: number;
};

const getColor = (value: number, max: number) => {
  // Very light purple to dark purple gradient
  const lightPurple = [199, 146, 255];
  const darkPurple = [88, 28, 135];
  const ratio = value / max;

  const r = Math.round(lightPurple[0] + ratio * (darkPurple[0] - lightPurple[0]));
  const g = Math.round(lightPurple[1] + ratio * (darkPurple[1] - lightPurple[1]));
  const b = Math.round(lightPurple[2] + ratio * (darkPurple[2] - lightPurple[2]));

  return `rgb(${r},${g},${b})`;
};

export const FilteredTokensChart: React.FC<FilteredTokensChartProps> = ({ data, width, height }) => {
  const margin = { top: 20, right: 20, bottom: 60, left: 60 };
  const xMax = width - margin.left - margin.right;
  const yMax = height - margin.top - margin.bottom;

  const xScale = useMemo(
    () =>
      scaleBand<Date>({
        range: [0, xMax],
        domain: data.map((d) => d.interval_start),
        padding: 0.2,
      }),
    [xMax, data],
  );

  const yScale = useMemo(
    () =>
      scaleLinear<number>({
        range: [yMax, 0],
        domain: [0, Math.max(...data.map((d) => Number(d.token_count)))],
        nice: true,
      }),
    [yMax, data],
  );

  const { showTooltip, hideTooltip, tooltipData, tooltipTop = 0, tooltipLeft = 0 } = useTooltip<DataPoint>();

  const maxTokenCount = Math.max(...data.map((d) => Number(d.token_count)));

  return (
    <div style={{ position: "relative" }}>
      <svg width={width} height={height}>
        <Group left={margin.left} top={margin.top}>
          <AxisLeft
            scale={yScale}
            tickLabelProps={() => ({
              fill: "rgba(255, 255, 255, 0.6)",
              fontSize: 11,
              textAnchor: "end",
              dy: "0.33em",
            })}
          />
          <AxisBottom
            top={yMax}
            scale={xScale}
            tickFormat={(d) => format(d, "HH:mm")}
            tickLabelProps={() => ({
              fill: "rgba(255, 255, 255, 0.6)",
              fontSize: 11,
              textAnchor: "middle",
            })}
          />
          {data.map((d) => {
            const barWidth = xScale.bandwidth();
            const barHeight = yMax - (yScale(Number(d.token_count)) ?? 0);
            const barX = xScale(d.interval_start);
            const barY = yMax - barHeight;

            return (
              <Bar
                key={`bar-${d.interval_start.toString()}`}
                x={barX}
                y={barY}
                width={barWidth}
                height={barHeight}
                fill={getColor(Number(d.token_count), maxTokenCount)}
                opacity={tooltipData && tooltipData !== d ? 0.6 : 1}
                onMouseEnter={() => {
                  showTooltip({
                    tooltipData: d,
                    tooltipTop: barY,
                    tooltipLeft: (barX ?? 0) + (barWidth ?? 0) / 2,
                  });
                }}
                onMouseLeave={hideTooltip}
              />
            );
          })}
        </Group>
      </svg>
      {tooltipData && (
        <Tooltip
          top={tooltipTop}
          left={tooltipLeft}
          style={{
            ...defaultStyles,
            transform: "translate(-50%, -100%)",
          }}
        >
          <div>
            <strong>Time:</strong> {format(tooltipData.interval_start, "HH:mm:ss")}
          </div>
          <div>
            <strong>Pumping tokens:</strong> {tooltipData.token_count}
          </div>
        </Tooltip>
      )}
    </div>
  );
};
