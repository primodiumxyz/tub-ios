/* 
 * @name getTokenTradeHistoryIntervalCandles
 * @param token_mint TEXT
 * @param interval_seconds INTEGER
 * @param candle_seconds INTEGER
 * @returns TABLE(
 *   bucket TIMESTAMPTZ,
 *   token_mint TEXT,
 *   open_price_usd NUMERIC,
 *   close_price_usd NUMERIC,
 *   high_price_usd NUMERIC,
 *   low_price_usd NUMERIC,
 *   volume_usd NUMERIC,
 *   token_metadata token_metadata
 * )
*/
CREATE OR REPLACE FUNCTION api.get_token_trade_history_interval_candles(
  token_mint TEXT,
  interval_seconds INTEGER,
  candle_seconds INTEGER DEFAULT 300
)
RETURNS SETOF trade_history_candle AS $$
WITH params AS (
  SELECT 
    NOW() - (interval '1 second' * interval_seconds) as start_time,
    NOW() as end_time
)
SELECT 
  time_bucket(concat(candle_seconds, ' seconds')::interval, created_at) as bucket,
  token_mint,
  FIRST(token_price_usd, created_at) as open_price_usd,
  LAST(token_price_usd, created_at) as close_price_usd,
  MAX(token_price_usd) as high_price_usd,
  MIN(token_price_usd) as low_price_usd,
  SUM(volume_usd) as volume_usd,
  FIRST(token_metadata::token_metadata, created_at) as token_metadata
FROM trade_history, params
WHERE 
  token_mint = $1
  AND created_at >= params.start_time
  AND created_at <= params.end_time
GROUP BY 1, 2
ORDER BY bucket DESC;
$$ LANGUAGE SQL STABLE; 