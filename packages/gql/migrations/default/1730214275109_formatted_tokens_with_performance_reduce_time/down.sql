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
        AND tph.created_at <= params.p_end + interval '1 day'
),
interval_prices AS (
    SELECT 
        token_id,
        mint,
        decimals,
        name,
        symbol,
        platform,
        price,
        created_at,
        p_start AS interval_start
    FROM filtered_token_stats
    CROSS JOIN params
    WHERE created_at <= params.p_end
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
        MAX(CASE WHEN created_at <= params.p_end THEN price END) AS latest_price,
        MIN(CASE WHEN created_at <= params.p_end THEN price END) AS initial_price,
        MAX(created_at) AS latest_created_at,
        interval_start
    FROM interval_prices
    CROSS JOIN params
    GROUP BY 
        token_id, mint, decimals, name, symbol, platform, interval_start
),
pump_stats AS (
    SELECT 
        fs.token_id,
        COUNT(*) AS trades_after,
        MAX(fs.created_at) - i.latest_created_at AS pump_duration,
        MAX(fs.price) AS final_pump_price
    FROM filtered_token_stats fs
    JOIN interval_stats i ON fs.token_id = i.token_id
    CROSS JOIN params
    WHERE fs.created_at > params.p_end
    AND fs.price > i.latest_price
    GROUP BY fs.token_id, i.latest_created_at
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
        ELSE ((COALESCE(p.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
    END AS increase_pct_after,
    i.trades,
    COALESCE(p.trades_after, 0) AS trades_after,
    COALESCE(p.pump_duration, interval '0') AS pump_duration,
    i.latest_created_at AS created_at,
    i.interval_start
FROM interval_stats i
LEFT JOIN pump_stats p ON i.token_id = p.token_id;
