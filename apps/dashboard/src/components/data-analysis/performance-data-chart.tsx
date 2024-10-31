import { useMemo, useState } from "react";
import { AxisBottom, AxisLeft } from "@visx/axis";
import { Group } from "@visx/group";
import { scaleLinear, scaleTime } from "@visx/scale";
import { LinePath } from "@visx/shape";
import { defaultStyles, Tooltip, useTooltip } from "@visx/tooltip";
import { format } from "date-fns";

import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { AFTER_INTERVALS } from "@/lib/constants";

type DataPoint = {
  interval_start: Date;
  stats: {
    increasePct: {
      avg: number;
      min: number;
      max: number;
    };
    trades: {
      avg: number;
      min: number;
      max: number;
    };
    tokenCount: number;
  }[];
};

type PerformanceChartProps = {
  data: DataPoint[];
  width: number;
  height: number;
};

const getLineColor = (index: number) => {
  // Generate different colors for each line
  const colors = [
    "#6DF8FA", // cyan
    "#FFD700", // gold
    "#FF69B4", // hot pink
    "#98FB98", // pale green
    "#DDA0DD", // plum
  ];
  return colors[index % colors.length];
};

export const PerformanceChart: React.FC<PerformanceChartProps> = ({ data, width, height }) => {
  const [maxYValue, setMaxYValue] = useState(500); // Start with 500%
  const [visibleIntervals, setVisibleIntervals] = useState<Set<string>>(new Set(AFTER_INTERVALS));

  const margin = { top: 20, right: 100, bottom: 60, left: 80 };
  const xMax = width - margin.left - margin.right;
  const yMax = height - margin.top - margin.bottom;

  const xScale = useMemo(
    () =>
      scaleTime<number>({
        range: [0, xMax],
        domain: [
          Math.min(...data.map((d) => d.interval_start.getTime())),
          Math.max(...data.map((d) => d.interval_start.getTime())),
        ],
      }),
    [xMax, data],
  );

  const yScale = useMemo(
    () =>
      scaleLinear<number>({
        range: [yMax, 0],
        domain: [0, maxYValue],
        nice: true,
      }),
    [yMax, maxYValue],
  );

  const {
    showTooltip,
    hideTooltip,
    tooltipData,
    tooltipTop = 0,
    tooltipLeft = 0,
  } = useTooltip<{
    date: Date;
    values: { afterInterval: string; value: number }[];
  }>();

  const toggleInterval = (interval: string) => {
    const newIntervals = new Set(visibleIntervals);
    if (newIntervals.has(interval)) {
      newIntervals.delete(interval);
    } else {
      newIntervals.add(interval);
    }
    setVisibleIntervals(newIntervals);
  };

  const toggleAll = () => {
    if (visibleIntervals.size === AFTER_INTERVALS.length) {
      setVisibleIntervals(new Set());
    } else {
      setVisibleIntervals(new Set(AFTER_INTERVALS));
    }
  };

  const handleMouseMove = (event: React.MouseEvent<SVGPathElement>, index: number) => {
    const svgElement = event.currentTarget.ownerSVGElement;
    if (!svgElement) return;

    const rect = svgElement.getBoundingClientRect();
    const mouseX = event.clientX - rect.left - margin.left;
    const xDate = xScale.invert(mouseX);

    const nearestPoint = data.reduce((prev, curr) => {
      return Math.abs(curr.interval_start.getTime() - xDate.getTime()) <
        Math.abs(prev.interval_start.getTime() - xDate.getTime())
        ? curr
        : prev;
    });

    const tooltipX = xScale(nearestPoint.interval_start.getTime());
    const tooltipY = yScale(nearestPoint.stats[index]?.increasePct.avg ?? 0);

    showTooltip({
      tooltipData: {
        date: nearestPoint.interval_start,
        values: nearestPoint.stats.map((s, i) => ({
          afterInterval: AFTER_INTERVALS[i],
          value: s.increasePct.avg,
        })),
      },
      tooltipLeft: tooltipX + margin.left,
      tooltipTop: tooltipY + margin.top,
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-end gap-8 w-full">
        <div className="w-[300px] flex items-center gap-4">
          <span className="text-sm text-muted-foreground whitespace-nowrap">Zoom</span>
          <Slider
            min={50}
            max={1000000}
            step={50}
            defaultValue={[500]}
            value={[maxYValue]}
            onValueChange={(value) => setMaxYValue(value[0])}
          />
        </div>
        <div className="flex gap-2 items-center">
          <Button
            variant={visibleIntervals.size === AFTER_INTERVALS.length ? "secondary" : "ghost"}
            onClick={toggleAll}
            size="sm"
          >
            All
          </Button>
          {AFTER_INTERVALS.map((interval) => (
            <Button
              key={interval}
              variant={visibleIntervals.has(interval) ? "secondary" : "ghost"}
              onClick={() => toggleInterval(interval)}
              size="sm"
            >
              {interval}
            </Button>
          ))}
        </div>
      </div>
      <div style={{ position: "relative" }}>
        <svg width={width} height={height}>
          <Group left={margin.left} top={margin.top}>
            <AxisLeft
              scale={yScale}
              tickFormat={(v) => `${v.toLocaleString()}%`}
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
              tickFormat={(d) => format(d.toString(), "HH:mm")}
              tickLabelProps={() => ({
                fill: "rgba(255, 255, 255, 0.6)",
                fontSize: 11,
                textAnchor: "middle",
              })}
            />
            {AFTER_INTERVALS.map(
              (interval, index) =>
                visibleIntervals.has(interval) && (
                  <LinePath
                    key={index}
                    data={data}
                    x={(d) => xScale(d.interval_start.getTime())}
                    y={(d) => yScale(d.stats[index]?.increasePct.avg ?? 0)}
                    stroke={getLineColor(index)}
                    strokeWidth={2}
                    onMouseMove={(event) => handleMouseMove(event, index)}
                    onMouseLeave={hideTooltip}
                  />
                ),
            )}
          </Group>

          {/* Update legend to only show visible intervals */}
          <Group left={width - margin.right + 20} top={margin.top}>
            {AFTER_INTERVALS.map(
              (interval, index) =>
                visibleIntervals.has(interval) && (
                  <Group key={index} top={index * 20}>
                    <line x1={0} y1={0} x2={20} y2={0} stroke={getLineColor(index)} strokeWidth={2} />
                    <text x={25} y={5} fontSize={11} fill="rgba(255, 255, 255, 0.6)">
                      {interval}
                    </text>
                  </Group>
                ),
            )}
          </Group>
        </svg>

        {tooltipData && (
          <Tooltip
            top={tooltipTop}
            left={tooltipLeft}
            style={{
              ...defaultStyles,
              position: "absolute",
              transform: "translate(-50%, -100%)",
              backgroundColor: "rgba(0, 0, 0, 0.85)",
              padding: "8px",
              borderRadius: "4px",
              color: "white",
              fontSize: "12px",
              pointerEvents: "none",
            }}
          >
            <div>
              <strong>Time:</strong> {format(tooltipData.date, "HH:mm:ss")}
            </div>
            {tooltipData.values
              .filter(({ afterInterval }) => visibleIntervals.has(afterInterval))
              .map(({ afterInterval, value }) => (
                <div key={afterInterval}>
                  <strong>{afterInterval}:</strong> {value.toLocaleString()}%
                </div>
              ))}
          </Tooltip>
        )}
      </div>
    </div>
  );
};
