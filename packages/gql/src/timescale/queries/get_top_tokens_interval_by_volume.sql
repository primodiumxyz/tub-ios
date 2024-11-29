CREATE OR REPLACE FUNCTION get_top_tokens_interval_by_volume(
  interval_seconds INTEGER,
  limit_count INTEGER DEFAULT 100
)
RETURNS TABLE (
  token_mint TEXT,
  token_metadata token_metadata,
  total_volume_usd NUMERIC,
  price_change_pct NUMERIC,
  avg_price_usd NUMERIC
) AS $$
WITH params AS (
  SELECT 
    NOW() - (interval '1 second' * interval_seconds) as start_time,
    NOW() as end_time
)
SELECT 
  -- For intervals ≤ 24h, use the continuous aggregate
  CASE 
    WHEN interval_seconds <= 86400 THEN
      SELECT 
        token_mint,
        FIRST(token_metadata, bucket) as token_metadata,
        SUM(total_volume_usd) as total_volume_usd,
        ((LAST(avg_price_usd, bucket) - FIRST(avg_price_usd, bucket)) / 
          NULLIF(FIRST(avg_price_usd, bucket), 0) * 100) as price_change_pct,
        AVG(avg_price_usd) as avg_price_usd
      FROM trade_history_5min t, params p
      WHERE 
        bucket >= p.start_time
        AND bucket <= p.end_time
      GROUP BY token_mint
      HAVING SUM(total_volume_usd) > 0  -- Filter out zero-volume tokens
      ORDER BY total_volume_usd DESC
      LIMIT limit_count

    -- For longer intervals, use the compressed hypertable
    ELSE
      SELECT 
        token_mint,
        FIRST(token_metadata, created_at) as token_metadata,
        SUM(volume_usd) as total_volume_usd,
        ((LAST(token_price_usd, created_at) - FIRST(token_price_usd, created_at)) / 
          NULLIF(FIRST(token_price_usd, created_at), 0) * 100) as price_change_pct,
        AVG(token_price_usd) as avg_price_usd
      FROM trade_history t, params p
      WHERE 
        created_at >= p.start_time
        AND created_at <= p.end_time
      GROUP BY token_mint
      HAVING SUM(volume_usd) > 0  -- Filter out zero-volume tokens
      ORDER BY total_volume_usd DESC
      LIMIT limit_count
  END;
$$ LANGUAGE SQL STABLE; 