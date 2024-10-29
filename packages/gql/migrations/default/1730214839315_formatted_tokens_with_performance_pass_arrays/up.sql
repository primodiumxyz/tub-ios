DROP VIEW IF EXISTS "public"."formatted_tokens_with_performance";
CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
WITH RECURSIVE params(p_start, p_end, p_intervals) AS (
    SELECT 
        CAST(current_setting('my.p_start', true) AS timestamptz),
        CAST(current_setting('my.p_end', true) AS timestamptz),
        string_to_array(current_setting('my.p_intervals', true), ',')::interval[]
),
intervals_expanded AS (
    SELECT 
        ordinality - 1 as interval_idx,
        interval_value
    FROM params,
    unnest(p_intervals) WITH ORDINALITY AS t(interval_value, ordinality)
),
max_interval AS (
    SELECT max(interval_value) as max_interval FROM intervals_expanded
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
    CROSS JOIN max_interval
    WHERE t.mint IS NOT NULL
        AND tph.created_at >= params.p_start
        AND tph.created_at <= params.p_end + max_interval
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
        MAX(created_at) FILTER (WHERE created_at <= params.p_end) AS latest_created_at,
        p_start AS interval_start
    FROM filtered_token_stats
    CROSS JOIN params
    GROUP BY 
        token_id, mint, decimals, name, symbol, platform, p_start
),
after_intervals AS (
    SELECT 
        i.token_id,
        p.interval_idx,
        p.interval_value,
        COUNT(*) AS trades,
        MIN(fs.price) FILTER (WHERE fs.created_at <= i.latest_created_at + p.interval_value) AS initial_price,
        MAX(fs.price) FILTER (WHERE fs.created_at <= i.latest_created_at + p.interval_value) AS final_price
    FROM interval_stats i
    CROSS JOIN intervals_expanded p
    JOIN filtered_token_stats fs ON i.token_id = fs.token_id
    WHERE fs.created_at > i.latest_created_at
        AND fs.created_at <= i.latest_created_at + p.interval_value
    GROUP BY i.token_id, p.interval_idx, p.interval_value
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
    array_agg(ai.trades ORDER BY ai.interval_idx) FILTER (WHERE ai.trades IS NOT NULL) AS trades_after,
    array_agg(
        CASE
            WHEN ai.initial_price = 0 THEN 0::double precision
            ELSE ((ai.final_price - ai.initial_price) * 100 / ai.initial_price)::double precision
        END ORDER BY ai.interval_idx
    ) FILTER (WHERE ai.trades IS NOT NULL) AS increase_pct_after,
    i.trades,
    i.latest_created_at AS created_at,
    i.interval_start
FROM interval_stats i
LEFT JOIN after_intervals ai ON i.token_id = ai.token_id
GROUP BY 
    i.token_id, i.mint, i.decimals, i.name, i.symbol, i.platform, 
    i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;
