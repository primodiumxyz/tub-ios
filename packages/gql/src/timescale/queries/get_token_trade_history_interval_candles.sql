CREATE OR REPLACE FUNCTION get_token_trade_history_interval_candles(
  token_mint TEXT,
  interval_seconds INTEGER,
  candle_seconds INTEGER DEFAULT 300
)
RETURNS TABLE (
  bucket TIMESTAMPTZ,
  open_price_usd NUMERIC,
  close_price_usd NUMERIC,
  high_price_usd NUMERIC,
  low_price_usd NUMERIC,
  volume_usd NUMERIC,
  token_metadata token_metadata
) AS $$
WITH params AS (
  SELECT 
    NOW() - (interval '1 second' * interval_seconds) as start_time,
    NOW() as end_time
)
SELECT * FROM (
  -- For intervals ≤ 24h, use the continuous aggregate
  SELECT 
    time_bucket(concat(candle_seconds, ' seconds')::interval, bucket) as bucket,
    FIRST(avg_price, bucket) as open_price_usd,
    LAST(avg_price, bucket) as close_price_usd,
    MAX(avg_price) as high_price_usd,
    MIN(avg_price) as low_price_usd,
    SUM(total_volume) as volume_usd,
    FIRST(token_metadata::token_metadata, bucket) as token_metadata
  FROM trade_history_5min, params
  WHERE 
    token_mint = $1
    AND bucket >= params.start_time
    AND bucket <= params.end_time
    AND interval_seconds <= 86400
  GROUP BY 1

  UNION ALL

  -- For longer intervals, use the compressed hypertable
  SELECT 
    time_bucket(concat(candle_seconds, ' seconds')::interval, created_at) as bucket,
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
    AND interval_seconds > 86400
  GROUP BY 1
) results
ORDER BY bucket DESC;
$$ LANGUAGE SQL STABLE; 