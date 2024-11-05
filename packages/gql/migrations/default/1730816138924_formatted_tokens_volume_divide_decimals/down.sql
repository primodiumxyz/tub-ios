CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
 WITH RECURSIVE params(p_start, p_end) AS (
         SELECT (current_setting('my.p_start'::text, true))::timestamp with time zone AS current_setting,
            (current_setting('my.p_end'::text, true))::timestamp with time zone AS current_setting
        ), filtered_token_stats AS (
         SELECT t.id AS token_id,
            t.mint,
            t.decimals,
            t.name,
            t.symbol,
            t.description,
            t.uri,
            t.mint_burnt,
            t.freeze_burnt,
            t.supply,
            t.is_pump_token,
            tph.price,
            tph.created_at,
                CASE
                    WHEN (tph.amount_in IS NOT NULL) THEN (tph.amount_in * tph.price)
                    WHEN (tph.amount_out IS NOT NULL) THEN (tph.amount_out * tph.price)
                    ELSE (0)::numeric
                END AS trade_volume
           FROM ((token t
             JOIN token_price_history tph ON ((t.id = tph.token)))
             CROSS JOIN params)
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_start) AND (tph.created_at <= params.p_end))
        ), latest_token_stats AS (
         SELECT DISTINCT ON (filtered_token_stats.mint) filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.decimals,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.description,
            filtered_token_stats.uri,
            filtered_token_stats.mint_burnt,
            filtered_token_stats.freeze_burnt,
            filtered_token_stats.supply,
            filtered_token_stats.is_pump_token,
            count(*) OVER (PARTITION BY filtered_token_stats.mint) AS trades,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at DESC) AS latest_price,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at) AS initial_price,
            max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at,
            sum(filtered_token_stats.trade_volume) OVER (PARTITION BY filtered_token_stats.mint) AS volume
           FROM filtered_token_stats
          ORDER BY filtered_token_stats.mint, filtered_token_stats.created_at DESC
        )
 SELECT latest_token_stats.token_id,
    latest_token_stats.mint,
    latest_token_stats.decimals,
    latest_token_stats.name,
    latest_token_stats.symbol,
    latest_token_stats.description,
    latest_token_stats.uri,
    latest_token_stats.mint_burnt,
    latest_token_stats.freeze_burnt,
    latest_token_stats.supply,
    latest_token_stats.is_pump_token,
    latest_token_stats.latest_price,
        CASE
            WHEN (latest_token_stats.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((latest_token_stats.latest_price - latest_token_stats.initial_price) * (100)::numeric) / latest_token_stats.initial_price))::double precision
        END AS increase_pct,
    latest_token_stats.trades,
    latest_token_stats.latest_created_at AS created_at,
    COALESCE((latest_token_stats.volume), (0)::numeric) AS volume
   FROM latest_token_stats;