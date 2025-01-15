CREATE MATERIALIZED VIEW api.tokens
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
    
    -- Stats
    SUM(total_volume_usd) as volume_usd_30m,
    SUM(total_trades) as trades_30m,
    
    -- Price changes
    CASE 
        WHEN FIRST(latest_price_usd, ts_bucket) = 0 THEN 0
        ELSE ((LAST(latest_price_usd, ts_bucket) - FIRST(latest_price_usd, ts_bucket)) 
              * 100 / NULLIF(FIRST(latest_price_usd, ts_bucket), 0))
    END as price_change_pct_30m,
    
    -- 2m stats (will be calculated in application layer from this 1m bucket data)
    SUM(total_volume_usd) as volume_usd_2m,
    SUM(total_trades) as trades_2m,
    
    -- 2m price change
    CASE 
        WHEN FIRST(latest_price_usd, ts_bucket) = 0 THEN 0
        ELSE ((LAST(latest_price_usd, ts_bucket) - FIRST(latest_price_usd, ts_bucket)) 
              * 100 / NULLIF(FIRST(latest_price_usd, ts_bucket), 0))
    END as price_change_pct_2m
FROM api.token_stats_1h
WHERE ts_bucket >= NOW() - INTERVAL '35 minutes'
GROUP BY time_bucket('1 minute', ts_bucket), token_mint
WITH NO DATA;
