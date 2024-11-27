/* @name GetTokenCandles */
WITH params AS (
  SELECT 
    now() as p_end,
    now() - :interval::interval as p_start
)
SELECT
  time_bucket(:candleInterval::interval, created_at) AS t,
  FIRST(token_price_usd, created_at) AS o,
  MAX(token_price_usd) AS h,
  MIN(token_price_usd) AS l,
  LAST(token_price_usd, created_at) AS c,
  SUM(volume_usd) AS v
FROM trade_history
CROSS JOIN params
WHERE token_mint = :tokenMint
  AND created_at >= p_start
  AND created_at < p_end
GROUP BY t
ORDER BY t ASC; 