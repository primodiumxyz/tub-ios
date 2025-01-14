CREATE MATERIALIZED VIEW api.token_stats_1h
WITH (timescaledb.continuous, timescaledb.materialized_only = false) AS
SELECT 
    time_bucket('1 minute', created_at) as ts_bucket,
    token_mint,
    -- Price tracking
    LAST(token_price_usd, created_at) as latest_price_usd,
    FIRST(token_price_usd, created_at) as first_price_usd,
    AVG(token_price_usd) as avg_price_usd,
    -- Running aggregates
    SUM(volume_usd) as total_volume_usd,
    COUNT(*) as total_trades,
    -- Latest state
    LAST(token_metadata, created_at) as token_metadata
FROM api.trade_history
GROUP BY time_bucket('1 minute', created_at), token_mint
WITH NO DATA;

-- Indexes optimized for our queries
CREATE INDEX ON api.token_stats_1h (token_mint, ts_bucket DESC);
CREATE INDEX ON api.token_stats_1h (ts_bucket DESC);

-- Refresh policy with no gap
SELECT add_continuous_aggregate_policy('api.token_stats_1h',
    start_offset => INTERVAL '1 hour',
    end_offset => INTERVAL '0', 
    schedule_interval => INTERVAL '5 seconds'
);