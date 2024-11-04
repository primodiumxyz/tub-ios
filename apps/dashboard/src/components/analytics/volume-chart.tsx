import React, { useMemo } from "react";
import { AxisBottom, AxisLeft } from "@visx/axis";
import { Group } from "@visx/group";
import { scaleBand, scaleLinear } from "@visx/scale";
import { Bar, LinePath } from "@visx/shape";
import { defaultStyles, Tooltip, useTooltip } from "@visx/tooltip";
import { format } from "date-fns";

type DataPoint = {
  interval_start: Date;
  token_count: string;
  total_volume: string;
};

type VolumeChartProps = {
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

const formatNumber = (num: number): string => {
  if (num >= 1_000_000_000) {
    return `${(num / 1_000_000_000).toFixed(1)}B`;
  }
  if (num >= 1_000_000) {
    return `${(num / 1_000_000).toFixed(1)}M`;
  }
  if (num >= 1_000) {
    return `${(num / 1_000).toFixed(1)}k`;
  }
  return num.toString();
};

export const VolumeChart: React.FC<VolumeChartProps> = ({ data, width, height }) => {
  const margin = { top: 20, right: 80, bottom: 60, left: 60 };
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

  const yScaleTokens = useMemo(
    () =>
      scaleLinear<number>({
        range: [yMax, 0],
        domain: [0, Math.max(...data.map((d) => Number(d.token_count)))],
        nice: true,
      }),
    [yMax, data],
  );

  const yScaleVolume = useMemo(
    () =>
      scaleLinear<number>({
        range: [yMax, 0],
        domain: [0, Math.max(...data.map((d) => Number(d.total_volume)))],
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
            scale={yScaleTokens}
            label="Token Count"
            labelOffset={40}
            tickFormat={(value) => formatNumber(Number(value))}
            labelProps={{
              fill: "rgba(255, 255, 255, 0.6)",
              fontSize: 12,
              textAnchor: "middle",
            }}
            tickLabelProps={() => ({
              fill: "rgba(255, 255, 255, 0.6)",
              fontSize: 11,
              textAnchor: "end",
              dy: "0.33em",
            })}
          />
          <AxisLeft
            scale={yScaleVolume}
            left={xMax}
            label="Total Volume"
            labelOffset={15}
            tickFormat={(value) => formatNumber(Number(value))}
            labelProps={{
              fill: "rgba(255, 255, 255, 0.4)",
              fontSize: 12,
              textAnchor: "middle",
            }}
            tickLabelProps={() => ({
              fill: "rgba(255, 255, 255, 0.4)",
              fontSize: 11,
              textAnchor: "start",
              dx: "0.33em",
            })}
            stroke="rgba(255, 255, 255, 0.1)"
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
            const barHeight = yMax - (yScaleTokens(Number(d.token_count)) ?? 0);
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
                opacity={tooltipData && tooltipData !== d ? 0.85 : 1}
                style={{ transition: "opacity 0.2s ease" }}
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
          <LinePath
            data={data}
            x={(d) => (xScale(d.interval_start) ?? 0) + xScale.bandwidth() / 2}
            y={(d) => yScaleVolume(Number(d.total_volume)) ?? 0}
            stroke="rgba(255, 255, 255, 0.8)"
            strokeWidth={2}
            style={{ pointerEvents: "none" }}
          />
        </Group>
      </svg>
      {tooltipData && (
        <Tooltip
          top={tooltipTop}
          left={tooltipLeft}
          style={{
            ...defaultStyles,
            backgroundColor: "rgba(0, 0, 0, 0.85)",
            padding: "12px",
            border: "1px solid rgba(255, 255, 255, 0.2)",
            borderRadius: "6px",
            boxShadow: "0 4px 6px rgba(0, 0, 0, 0.1)",
            transform: "translate(-50%, -100%)",
            transition: "all 0.15s ease",
          }}
        >
          <div style={{ marginBottom: "8px", fontSize: "12px", color: "#fff" }}>
            <strong style={{ color: "rgba(255, 255, 255, 0.9)" }}>
              {format(tooltipData.interval_start, "HH:mm:ss")}
            </strong>
          </div>
          <div
            style={{
              fontSize: "11px",
              color: "rgba(255, 255, 255, 0.7)",
              display: "flex",
              justifyContent: "space-between",
              marginBottom: "4px",
            }}
          >
            <span>Pumping tokens:</span>
            <strong style={{ marginLeft: "12px", color: "#fff" }}>
              {formatNumber(Number(tooltipData.token_count))}
            </strong>
          </div>
          <div
            style={{
              fontSize: "11px",
              color: "rgba(255, 255, 255, 0.7)",
              display: "flex",
              justifyContent: "space-between",
            }}
          >
            <span>Total volume:</span>
            <strong style={{ marginLeft: "12px", color: "#fff" }}>
              {formatNumber(Number(tooltipData.total_volume))}
            </strong>
          </div>
        </Tooltip>
      )}
    </div>
  );
};
