-- Create materialized view for rolling window stats
CREATE MATERIALIZED VIEW api.token_rolling_stats_30min AS
WITH recent_stats AS (
    SELECT 
        token_mint,
        ts_bucket,
        total_volume_usd,
        total_trades,
        latest_price_usd,
        first_price_usd
    FROM api.token_stats_1h
    WHERE ts_bucket >= NOW() - INTERVAL '35 minutes'  -- Extra buffer for calculations
)
SELECT 
    token_mint as mint,
    -- 30m stats
    SUM(total_volume_usd) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '30 minutes'
    ) as volume_usd_30m,
    SUM(total_trades) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '30 minutes'
    ) as trades_30m,
    -- 2m stats
    SUM(total_volume_usd) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '2 minutes'
    ) as volume_usd_2m,
    SUM(total_trades) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '2 minutes'
    ) as trades_2m,
    -- Price changes
    100.0 * (
        MAX(latest_price_usd) - MIN(first_price_usd) FILTER (
            WHERE ts_bucket >= NOW() - INTERVAL '30 minutes'
        )
    ) / NULLIF(MIN(first_price_usd) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '30 minutes'
    ), 0) as price_change_pct_30m,
    100.0 * (
        MAX(latest_price_usd) - MIN(first_price_usd) FILTER (
            WHERE ts_bucket >= NOW() - INTERVAL '2 minutes'
        )
    ) / NULLIF(MIN(first_price_usd) FILTER (
        WHERE ts_bucket >= NOW() - INTERVAL '2 minutes'
    ), 0) as price_change_pct_2m
FROM recent_stats
GROUP BY token_mint;

-- Create indexes
CREATE INDEX ON api.token_rolling_stats_30min (mint);
CREATE INDEX ON api.token_rolling_stats_30min (volume_usd_30m DESC);