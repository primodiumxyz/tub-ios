DROP VIEW IF EXISTS "public"."formatted_tokens";

CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
 WITH RECURSIVE params(p_since) AS (
         SELECT (current_setting('my.p_since'::text, true))::timestamp with time zone AS current_setting
        ), filtered_token_stats AS (
         SELECT t.id AS token_id,
            t.mint,
            t.name,
            t.symbol,
            t.platform,
            tph.price,
            tph.created_at
           FROM ((token t
             JOIN token_price_history tph ON ((t.id = tph.token)))
             CROSS JOIN params)
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_since))
        ), latest_token_stats AS (
         SELECT filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.platform,
            count(*) AS trades,
            max(filtered_token_stats.price) AS latest_price,
            min(filtered_token_stats.price) AS initial_price,
            max(filtered_token_stats.created_at) AS latest_created_at
           FROM filtered_token_stats
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.platform
        )
 SELECT latest_token_stats.token_id,
    latest_token_stats.mint,
    latest_token_stats.name,
    latest_token_stats.symbol,
    latest_token_stats.latest_price,
        CASE
            WHEN (latest_token_stats.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((latest_token_stats.latest_price - latest_token_stats.initial_price) / latest_token_stats.initial_price) * (100)::numeric))::double precision
        END AS increase_pct,
    latest_token_stats.trades,
    latest_token_stats.latest_created_at AS created_at,
    latest_token_stats.platform
   FROM latest_token_stats;
