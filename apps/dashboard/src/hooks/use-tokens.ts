import { useCallback, useEffect, useMemo, useState } from "react";

import { Token } from "@/lib/types";

export const useTokens = (): {
  tokens: Token[];
  fetching: boolean;
  error: string | undefined;
} => {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [fetching, setFetching] = useState(true);
  const [error, setError] = useState<string | undefined>(undefined);

  const fetchTokens = useCallback(async () => {
    try {
      setFetching(true);

      // TODO: implement

      setTokens([]);
      setFetching(false);
    } catch (err) {
      setError((err as Error).message);
      setFetching(false);
    }
  }, []);

  useEffect(() => {
    fetchTokens();
    const interval = setInterval(() => fetchTokens(), 5_000);
    return () => clearInterval(interval);
  }, [fetchTokens]);

  return useMemo(
    () => ({
      tokens,
      fetching,
      error,
    }),
    [tokens, fetching, error],
  );
};
