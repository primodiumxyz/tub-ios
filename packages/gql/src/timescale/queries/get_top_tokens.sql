/* @name GetTopTokensByVolume */
WITH params AS (
  SELECT 
    now() as p_end,
    now() - :interval::interval as p_start
)
SELECT
  token_mint,
  token_metadata,
  SUM(total_volume) as volume_usd,
  SUM(trade_count) as trade_count,
  p_start as interval_start,
  p_end as interval_end
FROM trade_history_5min
CROSS JOIN params
WHERE bucket >= p_start
  AND bucket < p_end
GROUP BY token_mint, token_metadata, p_start, p_end
HAVING SUM(total_volume) > 0
ORDER BY volume_usd DESC
LIMIT :limit; 