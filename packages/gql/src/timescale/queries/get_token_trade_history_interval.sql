CREATE OR REPLACE FUNCTION get_token_trade_history_interval(
  token_mint TEXT,
  interval_seconds INTEGER
)
RETURNS TABLE (
  created_at TIMESTAMPTZ,
  token_mint TEXT,
  token_metadata token_metadata,
  token_price_usd NUMERIC,
  volume_usd NUMERIC
) AS $$
WITH params AS (
  SELECT 
    NOW() - (interval '1 second' * interval_seconds) as start_time,
    NOW() as end_time
)
SELECT 
  -- For intervals ≤ 24h, use the continuous aggregate for better performance
  CASE 
    WHEN interval_seconds <= 86400 THEN
      SELECT 
        bucket as created_at,
        token_mint,
        token_metadata,
        avg_price as token_price_usd,
        total_volume as volume_usd
      FROM trade_history_5min, params
      WHERE 
        token_mint = $1
        AND bucket >= params.start_time
        AND bucket <= params.end_time

    -- For longer intervals, use the compressed hypertable
    ELSE
      SELECT 
        created_at,
        token_mint,
        token_metadata,
        token_price_usd,
        volume_usd
      FROM trade_history, params
      WHERE 
        token_mint = $1
        AND created_at >= params.start_time
        AND created_at <= params.end_time
  END
ORDER BY created_at DESC;
$$ LANGUAGE SQL STABLE; 