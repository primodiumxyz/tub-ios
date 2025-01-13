CREATE MATERIALIZED VIEW api.token_stats_1h
WITH (timescaledb.continuous,
      timescaledb.materialized_only = false) AS
SELECT 
    time_bucket('1 minute', bucket) as ts_bucket,
    token_mint,
    -- Latest values
    LAST(latest_price_usd, bucket) as latest_price_usd,
    LAST(token_metadata, bucket) as token_metadata,
    -- 30m aggregations
    SUM(total_volume_usd) as total_volume_usd,
    SUM(trade_count) as total_trades,
    -- First price in window for price change calculation
    FIRST(latest_price_usd, bucket) as initial_price_usd
FROM api.trade_history_1min
GROUP BY ts_bucket, token_mint
WITH NO DATA;

-- Create indexes for better query performance
CREATE INDEX ON api.token_stats_1h (ts_bucket DESC, token_mint);
CREATE INDEX ON api.token_stats_1h (token_mint, ts_bucket DESC);

-- Refresh every 10 seconds
SELECT add_continuous_aggregate_policy('api.token_stats_1h',
    start_offset => INTERVAL '1 hour',
    end_offset => INTERVAL '0',
    schedule_interval => INTERVAL '10 seconds'
);
