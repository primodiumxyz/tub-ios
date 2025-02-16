
DROP FUNCTION IF EXISTS public.get_formatted_tokens_interval(interval);

CREATE OR REPLACE FUNCTION public.get_formatted_tokens(p_since timestamp with time zone)
 RETURNS SETOF formatted_tokens
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM set_config('my.p_since', p_since::text, true);
    RETURN QUERY
    SELECT *
    FROM formatted_tokens;
END;
$function$

CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
 WITH RECURSIVE params(p_since) AS (
         SELECT (current_setting('my.p_since'::text, true))::timestamp with time zone AS current_setting
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
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_since))
        ), latest_token_stats AS (
         SELECT DISTINCT ON (filtered_token_stats.mint) filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.decimals,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.platform,
            count(*) OVER (PARTITION BY filtered_token_stats.mint) AS trades,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at DESC) AS latest_price,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at) AS initial_price,
            max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at
           FROM filtered_token_stats
          ORDER BY filtered_token_stats.mint, filtered_token_stats.created_at DESC
        )
 SELECT latest_token_stats.token_id,
    latest_token_stats.mint,
    latest_token_stats.decimals,
    latest_token_stats.name,
    latest_token_stats.symbol,
    latest_token_stats.latest_price,
        CASE
            WHEN (latest_token_stats.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((latest_token_stats.latest_price - latest_token_stats.initial_price) * (100)::numeric) / latest_token_stats.initial_price))::double precision
        END AS increase_pct,
    latest_token_stats.trades,
    latest_token_stats.latest_created_at AS created_at,
    latest_token_stats.platform
   FROM latest_token_stats;
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- CREATE OR REPLACE VIEW "public"."formatted_tokens" AS
--  WITH RECURSIVE params(p_since) AS (
--          SELECT (current_setting('my.p_since'::text, true))::timestamp with time zone AS current_setting
--         ), filtered_token_stats AS (
--          SELECT t.id AS token_id,
--             t.mint,
--             t.decimals,
--             t.name,
--             t.symbol,
--             t.platform,
--             tph.price,
--             tph.created_at
--            FROM ((token t
--              JOIN token_price_history tph ON ((t.id = tph.token)))
--              CROSS JOIN params)
--           WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_since))
--         ), latest_token_stats AS (
--          SELECT DISTINCT ON (filtered_token_stats.mint)
--             filtered_token_stats.token_id,
--             filtered_token_stats.mint,
--             filtered_token_stats.decimals,
--             filtered_token_stats.name,
--             filtered_token_stats.symbol,
--             filtered_token_stats.platform,
--             count(*) OVER (PARTITION BY filtered_token_stats.mint) AS trades,
--             first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at DESC) AS latest_price,
--             first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at ASC) AS initial_price,
--             max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at
--            FROM filtered_token_stats
--           ORDER BY filtered_token_stats.mint, filtered_token_stats.created_at DESC
--         )
--  SELECT latest_token_stats.token_id,
--     latest_token_stats.mint,
--     latest_token_stats.decimals,
--     latest_token_stats.name,
--     latest_token_stats.symbol,
--     latest_token_stats.latest_price,
--         CASE
--             WHEN (latest_token_stats.initial_price = (0)::numeric) THEN (0)::double precision
--             ELSE ((((latest_token_stats.latest_price - latest_token_stats.initial_price) * (100)::numeric) / latest_token_stats.initial_price))::double precision
--         END AS increase_pct,
--     latest_token_stats.trades,
--     latest_token_stats.latest_created_at AS created_at,
--     latest_token_stats.platform
--    FROM latest_token_stats;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- CREATE OR REPLACE VIEW "public"."formatted_tokens" AS
--  WITH RECURSIVE params(p_since) AS (
--          SELECT (current_setting('my.p_since'::text, true))::timestamp with time zone AS current_setting
--         ), filtered_token_stats AS (
--          SELECT t.id AS token_id,
--             t.mint,
--             t.decimals,
--             t.name,
--             t.symbol,
--             t.platform,
--             tph.price,
--             tph.created_at
--            FROM ((token t
--              JOIN token_price_history tph ON ((t.id = tph.token)))
--              CROSS JOIN params)
--           WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_since))
--         ), latest_token_stats AS (
--          SELECT filtered_token_stats.token_id,
--             filtered_token_stats.mint,
--             filtered_token_stats.decimals,
--             filtered_token_stats.name,
--             filtered_token_stats.symbol,
--             filtered_token_stats.platform,
--             count(*) AS trades,
--             first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.token_id ORDER BY filtered_token_stats.created_at DESC) AS latest_price,
--             first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.token_id ORDER BY filtered_token_stats.created_at ASC) AS initial_price,
--             max(filtered_token_stats.created_at) AS latest_created_at
--            FROM filtered_token_stats
--           GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.platform, filtered_token_stats.price, filtered_token_stats.created_at
--         )
--  SELECT latest_token_stats.token_id,
--     latest_token_stats.mint,
--     latest_token_stats.decimals,
--     latest_token_stats.name,
--     latest_token_stats.symbol,
--     latest_token_stats.latest_price,
--         CASE
--             WHEN (latest_token_stats.initial_price = (0)::numeric) THEN (0)::double precision
--             ELSE ((((latest_token_stats.latest_price - latest_token_stats.initial_price) * (100)::numeric) / latest_token_stats.initial_price))::double precision
--         END AS increase_pct,
--     latest_token_stats.trades,
--     latest_token_stats.latest_created_at AS created_at,
--     latest_token_stats.platform
--    FROM latest_token_stats;

CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
 WITH RECURSIVE params(p_since) AS (
         SELECT (current_setting('my.p_since'::text, true))::timestamp with time zone AS current_setting
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
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_since))
        ), latest_token_stats AS (
         SELECT filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.decimals,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.platform,
            count(*) AS trades,
            max(filtered_token_stats.price) AS latest_price,
            min(filtered_token_stats.price) AS initial_price,
            max(filtered_token_stats.created_at) AS latest_created_at
           FROM filtered_token_stats
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.platform
        )
 SELECT latest_token_stats.token_id,
    latest_token_stats.mint,
    latest_token_stats.decimals,
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