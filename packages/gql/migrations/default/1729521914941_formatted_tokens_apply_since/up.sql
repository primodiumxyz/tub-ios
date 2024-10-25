CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
WITH RECURSIVE params(p_since) AS (
    SELECT CAST(current_setting('my.p_since', true) AS timestamptz)
),
filtered_token_stats AS (
    SELECT 
        t.id AS token_id,
        t.mint,
        t.name,
        t.symbol,
        t.platform,
        tph.price,
        tph.created_at
    FROM token t
    JOIN token_price_history tph ON t.id = tph.token
    CROSS JOIN params
    WHERE t.mint IS NOT NULL
        AND tph.created_at >= params.p_since
),
latest_token_stats AS (
    SELECT 
        token_id,
        mint,
        name,
        symbol,
        platform,
        COUNT(*) AS trades,
        MAX(price) AS latest_price,
        MIN(price) AS initial_price,
        MAX(created_at) AS latest_created_at
    FROM filtered_token_stats
    GROUP BY token_id, mint, name, symbol, platform
)
SELECT 
    token_id,
    mint,
    name,
    symbol,
    latest_price,
    CASE
        WHEN initial_price = 0 THEN 0::double precision
        ELSE ((latest_price - initial_price) / initial_price * 100)::double precision
    END AS increase_pct,
    trades,
    latest_created_at AS created_at,
    platform
FROM latest_token_stats;
