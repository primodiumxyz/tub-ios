/* @name GetTokenTradeHistoryIntervalCandles */
CREATE OR REPLACE FUNCTION get_token_trade_history_candles(
  token_mint TEXT,
  interval_seconds INTEGER,
  candle_seconds INTEGER
)
RETURNS TABLE (
  bucket TIMESTAMPTZ,
  token_mint TEXT,
  token_metadata token_metadata,
  open_price_usd NUMERIC,
  close_price_usd NUMERIC,
  high_price_usd NUMERIC,
  low_price_usd NUMERIC,
  volume NUMERIC
) AS $$
WITH params AS (
  SELECT 
    NOW() - (interval '1 second' * interval_seconds) as start_time,
    NOW() as end_time,
    (interval '1 second' * candle_seconds) as bucket_interval
)
SELECT 
  -- For small intervals (≤ 24h), use the continuous aggregate
  CASE 
    WHEN interval_seconds <= 86400 THEN
      SELECT 
        time_bucket(p.bucket_interval, bucket) as bucket,
        token_mint,
        FIRST(token_metadata, bucket) as token_metadata,
        FIRST(avg_price, bucket) as open_price_usd,
        LAST(avg_price, bucket) as close_price_usd,
        MAX(avg_price) as high_price_usd,
        MIN(avg_price) as low_price_usd,
        SUM(total_volume) as volume
      FROM trade_history_5min t, params p
      WHERE 
        token_mint = $1
        AND bucket >= p.start_time
        AND bucket <= p.end_time
      GROUP BY 1, 2

    -- For larger intervals, use the compressed hypertable
    ELSE
      SELECT 
        time_bucket(p.bucket_interval, created_at) as bucket,
        token_mint,
        FIRST(token_metadata, created_at) as token_metadata,
        FIRST(token_price_usd, created_at) as open_price_usd,
        LAST(token_price_usd, created_at) as close_price_usd,
        MAX(token_price_usd) as high_price_usd,
        MIN(token_price_usd) as low_price_usd,
        SUM(volume_usd) as volume
      FROM trade_history t, params p
      WHERE 
        token_mint = $1
        AND created_at >= p.start_time
        AND created_at <= p.end_time
      GROUP BY 1, 2
  END
ORDER BY bucket DESC;
$$ LANGUAGE SQL STABLE; 