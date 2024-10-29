CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
WITH RECURSIVE params(p_start, p_end) AS (
    SELECT 
        CAST(current_setting('my.p_start', true) AS timestamptz),
        CAST(current_setting('my.p_end', true) AS timestamptz)
),
filtered_token_stats AS (
    SELECT 
        t.id AS token_id,
        t.mint,
        t.decimals,
        t.name,
        t.symbol,
        t.platform,
        tph.price,
        tph.created_at
    FROM token t
    JOIN token_price_history tph ON t.id = tph.token
    CROSS JOIN params
    WHERE t.mint IS NOT NULL
        AND tph.created_at >= params.p_start
        -- Add an upper bound to limit data fetched
        AND tph.created_at <= params.p_end + interval '1 day'
),
interval_stats AS (
    SELECT 
        token_id,
        mint,
        decimals,
        name,
        symbol,
        platform,
        COUNT(*) AS trades,
        first_value(price) OVER w AS latest_price,
        first_value(price) OVER w_asc AS initial_price,
        max(created_at) AS latest_created_at,
        p_start AS interval_start
    FROM filtered_token_stats
    CROSS JOIN params
    WHERE created_at <= p_end
    GROUP BY 
        token_id, mint, decimals, name, symbol, platform, price, created_at, p_start, p_end
    WINDOW 
        w AS (PARTITION BY mint ORDER BY created_at DESC),
        w_asc AS (PARTITION BY mint ORDER BY created_at ASC)
),
pump_prices AS (
    SELECT 
        fs.token_id,
        fs.created_at,
        fs.price,
        i.latest_price AS interval_end_price,
        i.latest_created_at AS interval_end_time
    FROM filtered_token_stats fs
    JOIN interval_stats i ON fs.token_id = i.token_id
    WHERE fs.created_at > i.latest_created_at
    AND fs.price > i.latest_price
),
continuous_pump AS (
    SELECT 
        token_id,
        COUNT(*) AS trades_after,
        MAX(created_at) - MIN(interval_end_time) AS pump_duration,
        MAX(price) AS final_pump_price
    FROM pump_prices
    GROUP BY token_id
)
SELECT 
    i.token_id,
    i.mint,
    i.decimals,
    i.name,
    i.symbol,
    i.platform,
    i.latest_price,
    CASE
        WHEN i.initial_price = 0 THEN 0::double precision
        ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
    END AS increase_pct,
    CASE
        WHEN i.latest_price = 0 THEN 0::double precision
        ELSE ((COALESCE(cp.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
    END AS increase_pct_after,
    i.trades,
    COALESCE(cp.trades_after, 0) AS trades_after,
    COALESCE(cp.pump_duration, interval '0') AS pump_duration,
    i.latest_created_at AS created_at,
    i.interval_start
FROM interval_stats i
LEFT JOIN continuous_pump cp ON i.token_id = cp.token_id;
