-- Drop existing policy first
DROP MATERIALIZED VIEW api.trade_history_1min CASCADE;

-- Recreate with better settings
CREATE MATERIALIZED VIEW api.trade_history_1min
WITH (timescaledb.continuous, 
      timescaledb.materialized_only = false) AS  -- Allow real-time aggregation
SELECT
  time_bucket('1 minute', created_at) AS bucket,
  token_mint,
  LAST(token_price_usd, created_at) as latest_price_usd,
  FIRST(id, created_at) as id,
  FIRST(token_metadata, created_at) as token_metadata,
  AVG(token_price_usd) as avg_price_usd,
  SUM(volume_usd) as total_volume_usd,
  COUNT(*) as trade_count
FROM api.trade_history
GROUP BY bucket, token_mint
WITH NO DATA;

-- More frequent refresh policy
SELECT add_continuous_aggregate_policy('api.trade_history_1min',
  start_offset => INTERVAL '24 hours',
  end_offset => INTERVAL '0',  -- Up to now
  schedule_interval => INTERVAL '10 seconds'
);
