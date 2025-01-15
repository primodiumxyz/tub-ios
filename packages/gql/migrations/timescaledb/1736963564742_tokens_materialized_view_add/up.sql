-- Base materialized view for token metadata and latest state
CREATE MATERIALIZED VIEW api.token_metadata
WITH (timescaledb.continuous, timescaledb.materialized_only = false) AS
SELECT 
    time_bucket('1 minute', ts_bucket) as bucket,
    token_mint as mint,
    -- Metadata (latest values)
    (LAST(token_metadata, ts_bucket)).name as name,
    (LAST(token_metadata, ts_bucket)).symbol as symbol,
    (LAST(token_metadata, ts_bucket)).description as description,
    (LAST(token_metadata, ts_bucket)).image_uri as image_uri,
    (LAST(token_metadata, ts_bucket)).external_url as external_url,
    COALESCE((LAST(token_metadata, ts_bucket)).decimals, 0) as decimals,
    COALESCE((LAST(token_metadata, ts_bucket)).supply, 0) as supply,
    COALESCE((LAST(token_metadata, ts_bucket)).is_pump_token, false) as is_pump_token,
    -- Latest price
    LAST(latest_price_usd, ts_bucket) as latest_price_usd,
    FIRST(latest_price_usd, ts_bucket) as first_price_usd
FROM api.token_stats_1h
WHERE (token_metadata).name IS NOT NULL
GROUP BY time_bucket('1 minute', ts_bucket), token_mint
WITH NO DATA;

-- 30m stats view
CREATE MATERIALIZED VIEW api.token_stats_30m
WITH (timescaledb.continuous, timescaledb.materialized_only = false) AS
SELECT 
    time_bucket('1 minute', ts_bucket) as bucket,
    token_mint as mint,
    SUM(total_volume_usd) as volume_usd_30m,
    SUM(total_trades) as trades_30m,
    100.0 * (LAST(latest_price_usd, ts_bucket) - FIRST(latest_price_usd, ts_bucket)) / 
        NULLIF(FIRST(latest_price_usd, ts_bucket), 0) as price_change_pct_30m
FROM api.token_stats_1h
WHERE ts_bucket >= time_bucket('1 minute', NOW()) - INTERVAL '30 minutes'
GROUP BY time_bucket('1 minute', ts_bucket), token_mint
WITH NO DATA;

-- 2m stats view
CREATE MATERIALIZED VIEW api.token_stats_2m
WITH (timescaledb.continuous, timescaledb.materialized_only = false) AS
SELECT 
    time_bucket('1 minute', ts_bucket) as bucket,
    token_mint as mint,
    SUM(total_volume_usd) as volume_usd_2m,
    SUM(total_trades) as trades_2m,
    100.0 * (LAST(latest_price_usd, ts_bucket) - FIRST(latest_price_usd, ts_bucket)) / 
        NULLIF(FIRST(latest_price_usd, ts_bucket), 0) as price_change_pct_2m
FROM api.token_stats_1h
WHERE ts_bucket >= time_bucket('1 minute', NOW()) - INTERVAL '2 minutes'
GROUP BY time_bucket('1 minute', ts_bucket), token_mint
WITH NO DATA;

-- Final view combining everything
CREATE VIEW api.tokens AS
SELECT 
    b.*,
    COALESCE(t30.volume_usd_30m, 0) as volume_usd_30m,
    COALESCE(t30.trades_30m, 0) as trades_30m,
    COALESCE(t30.price_change_pct_30m, 0) as price_change_pct_30m,
    COALESCE(t2.volume_usd_2m, 0) as volume_usd_2m,
    COALESCE(t2.trades_2m, 0) as trades_2m,
    COALESCE(t2.price_change_pct_2m, 0) as price_change_pct_2m
FROM (
    SELECT DISTINCT ON (mint)
        *
    FROM api.token_metadata
    ORDER BY mint, bucket DESC
) b
LEFT JOIN (
    SELECT DISTINCT ON (mint)
        mint,
        volume_usd_30m,
        trades_30m,
        price_change_pct_30m
    FROM api.token_stats_30m
    ORDER BY mint, bucket DESC
) t30 ON b.mint = t30.mint
LEFT JOIN (
    SELECT DISTINCT ON (mint)
        mint,
        volume_usd_2m,
        trades_2m,
        price_change_pct_2m
    FROM api.token_stats_2m
    ORDER BY mint, bucket DESC
) t2 ON b.mint = t2.mint;