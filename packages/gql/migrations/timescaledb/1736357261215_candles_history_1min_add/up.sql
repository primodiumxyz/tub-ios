-- Compute 1 minute candles from trade history
CREATE MATERIALIZED VIEW api.candles_history_1min
WITH (timescaledb.continuous, 
      timescaledb.materialized_only = false) AS
SELECT
    time_bucket('1 minute', created_at) AS bucket,
    token_mint,
    FIRST(token_price_usd, created_at) as open_price_usd,
    LAST(token_price_usd, created_at) as close_price_usd,
    MAX(token_price_usd) as high_price_usd,
    MIN(token_price_usd) as low_price_usd,
    SUM(volume_usd) as volume_usd,
    LAST(token_metadata, created_at) as token_metadata
FROM api.trade_history
GROUP BY bucket, token_mint
WITH NO DATA;

-- Add indexes for better performance
CREATE INDEX ON api.candles_history_1min (bucket DESC, token_mint);
CREATE INDEX ON api.candles_history_1min (token_mint, bucket DESC);

-- Refresh every 5 seconds for the last 24 hours with no gap
SELECT add_continuous_aggregate_policy('api.candles_history_1min',
    start_offset => INTERVAL '24 hours',
    end_offset => INTERVAL '0',
    schedule_interval => INTERVAL '5 seconds'
);