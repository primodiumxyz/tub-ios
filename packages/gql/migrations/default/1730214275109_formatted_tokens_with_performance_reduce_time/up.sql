CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
 WITH RECURSIVE params(p_start, p_end) AS (
         SELECT (current_setting('my.p_start'::text, true))::timestamp with time zone AS current_setting,
            (current_setting('my.p_end'::text, true))::timestamp with time zone AS current_setting
        ), filtered_token_stats AS (
         SELECT t.id AS token_id,
            t.mint,
            t.decimals,
            t.name,
            t.symbol,
            t.platform,
            tph.price,
            tph.created_at
           FROM ((token t
             JOIN token_price_history tph ON ((t.id = tph.token)))
             CROSS JOIN params)
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_start) AND (tph.created_at <= (params.p_end + '1 hour'::interval)))
        ), interval_prices AS (
         SELECT filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.decimals,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.platform,
            filtered_token_stats.price,
            filtered_token_stats.created_at,
            params.p_start AS interval_start
           FROM (filtered_token_stats
             CROSS JOIN params)
          WHERE (filtered_token_stats.created_at <= params.p_end)
        ), interval_stats AS (
         SELECT interval_prices.token_id,
            interval_prices.mint,
            interval_prices.decimals,
            interval_prices.name,
            interval_prices.symbol,
            interval_prices.platform,
            count(*) AS trades,
            max(
                CASE
                    WHEN (interval_prices.created_at <= params.p_end) THEN interval_prices.price
                    ELSE NULL::numeric
                END) AS latest_price,
            min(
                CASE
                    WHEN (interval_prices.created_at <= params.p_end) THEN interval_prices.price
                    ELSE NULL::numeric
                END) AS initial_price,
            max(interval_prices.created_at) AS latest_created_at,
            interval_prices.interval_start
           FROM (interval_prices
             CROSS JOIN params)
          GROUP BY interval_prices.token_id, interval_prices.mint, interval_prices.decimals, interval_prices.name, interval_prices.symbol, interval_prices.platform, interval_prices.interval_start
        ), pump_stats AS (
         SELECT fs.token_id,
            count(*) AS trades_after,
            (max(fs.created_at) - i_1.latest_created_at) AS pump_duration,
            max(fs.price) AS final_pump_price
           FROM ((filtered_token_stats fs
             JOIN interval_stats i_1 ON ((fs.token_id = i_1.token_id)))
             CROSS JOIN params)
          WHERE ((fs.created_at > params.p_end) AND (fs.price > i_1.latest_price))
          GROUP BY fs.token_id, i_1.latest_created_at
        )
 SELECT i.token_id,
    i.mint,
    i.decimals,
    i.name,
    i.symbol,
    i.platform,
    i.latest_price,
        CASE
            WHEN (i.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((i.latest_price - i.initial_price) * (100)::numeric) / i.initial_price))::double precision
        END AS increase_pct,
        CASE
            WHEN (i.latest_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((COALESCE(p.final_pump_price, i.latest_price) - i.latest_price) * (100)::numeric) / i.latest_price))::double precision
        END AS increase_pct_after,
    i.trades,
    COALESCE(p.trades_after, (0)::bigint) AS trades_after,
    COALESCE(p.pump_duration, '00:00:00'::interval) AS pump_duration,
    i.latest_created_at AS created_at,
    i.interval_start
   FROM (interval_stats i
     LEFT JOIN pump_stats p ON ((i.token_id = p.token_id)));
