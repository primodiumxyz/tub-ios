import { useAnalyticsParamsContext } from "@/providers/analytics-params-provider";

export const useAnalyticsParams = () => {
  const { params, setFrom, setTo, setPeriodMs } = useAnalyticsParamsContext();

  return {
    from: params.from,
    to: params.to,
    periodMs: params.periodMs,

    setFrom: (value: Date) => {
      setFrom(value);
      setPeriodMs(params.to.getTime() - value.getTime());
    },
    setTo: (value: Date) => {
      setTo(value);
      setPeriodMs(value.getTime() - params.from.getTime());
    },
  };
};
