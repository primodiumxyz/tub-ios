-- Create materialized view for rolling window stats
CREATE MATERIALIZED VIEW api.token_rolling_stats_30min AS 
WITH recent_stats AS (
    SELECT 
        token_mint,
        ts_bucket,
        total_volume_usd,
        total_trades,
        latest_price_usd,
        first_price_usd,
        token_metadata
    FROM api.token_stats_1h
    WHERE ts_bucket >= NOW() - INTERVAL '35 minutes'
),
latest_metadata AS (
    SELECT 
        token_mint,
        LAST(token_metadata, ts_bucket) as token_metadata
    FROM recent_stats
    GROUP BY token_mint
)
SELECT 
    recent_stats.token_mint as mint,
    -- Basic Metadata fields
    (m.token_metadata).name as name,
    (m.token_metadata).symbol as symbol,
    (m.token_metadata).decimals as decimals,
    (m.token_metadata).supply as supply,
    (m.token_metadata).description as description,
    (m.token_metadata).external_url as external_url,
    (m.token_metadata).image_uri as image_uri,
    (m.token_metadata).is_pump_token as is_pump_token,
    -- Stats fields
    COALESCE(SUM(recent_stats.total_volume_usd) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '30 minutes'), 0) as volume_usd_30m,
    COALESCE(SUM(recent_stats.total_trades) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '30 minutes'), 0) as trades_30m,
    COALESCE(SUM(recent_stats.total_volume_usd) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '1 minutes'), 0) as volume_usd_1m,
    COALESCE(SUM(recent_stats.total_trades) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '1 minutes'), 0) as trades_1m,
    COALESCE(LAST(recent_stats.latest_price_usd, recent_stats.ts_bucket), 0) as latest_price_usd,
    -- Price change calculations
    COALESCE(100.0 * (LAST(recent_stats.latest_price_usd, recent_stats.ts_bucket) - FIRST(recent_stats.first_price_usd, recent_stats.ts_bucket) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '30 minutes'))
        / NULLIF(FIRST(recent_stats.first_price_usd, recent_stats.ts_bucket) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '30 minutes'), 0), 0) as price_change_pct_30m,
    COALESCE(100.0 * (LAST(recent_stats.latest_price_usd, recent_stats.ts_bucket) - FIRST(recent_stats.first_price_usd, recent_stats.ts_bucket) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '1 minutes'))
        / NULLIF(FIRST(recent_stats.first_price_usd, recent_stats.ts_bucket) FILTER (WHERE recent_stats.ts_bucket >= NOW() - INTERVAL '1 minutes'), 0), 0) as price_change_pct_1m
FROM recent_stats
JOIN latest_metadata m ON m.token_mint = recent_stats.token_mint
GROUP BY recent_stats.token_mint, m.token_metadata;

-- Create indexes
CREATE UNIQUE INDEX ON api.token_rolling_stats_30min (mint);
CREATE INDEX ON api.token_rolling_stats_30min (volume_usd_30m DESC);