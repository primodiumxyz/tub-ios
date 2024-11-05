
-- alter table "public"."token" add column "created_at" timestamptz
--  null default now();

CREATE OR REPLACE FUNCTION public.get_formatted_tokens_period(p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS SETOF formatted_tokens
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM set_config('my.p_start', p_start::text, true);
    PERFORM set_config('my.p_end', p_end::text, true);
    RETURN QUERY
    SELECT *
    FROM formatted_tokens;
END;
$function$;

alter table "public"."token" alter column "created_at" set not null;

CREATE OR REPLACE VIEW hourly_swaps AS
SELECT
  date_trunc('hour', created_at) AS hour,
  COUNT(*) AS count
FROM
  token_price_history
GROUP BY
  date_trunc('hour', created_at)
ORDER BY
  hour;

CREATE OR REPLACE VIEW hourly_new_tokens AS
SELECT
  date_trunc('hour', created_at) AS hour,
  COUNT(*) AS count
FROM
  token
GROUP BY
  date_trunc('hour', created_at)
ORDER BY
  hour;

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
            t.platform,
            tph.price,
            tph.created_at,
            params.p_start AS interval_start
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
            filtered_token_stats.platform,
            count(*) OVER (PARTITION BY filtered_token_stats.mint) AS trades,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at DESC) AS latest_price,
            first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at) AS initial_price,
            max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at,
            filtered_token_stats.interval_start
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
    latest_token_stats.platform,
    latest_token_stats.interval_start
   FROM latest_token_stats;

DROP FUNCTION IF EXISTS public.get_formatted_tokens_intervals_within_period(timestamptz, timestamptz, interval);
CREATE OR REPLACE FUNCTION public.get_formatted_tokens_intervals_within_period(
  p_start timestamptz,
  p_end timestamptz,
  p_interval interval
)
RETURNS SETOF formatted_tokens AS $$
DECLARE
  current_start timestamptz;
  current_end timestamptz;
BEGIN
  current_start := p_start;
  
  WHILE current_start < p_end LOOP
    current_end := least(current_start + p_interval, p_end);
    
    PERFORM set_config('my.p_start', current_start::text, true);
    PERFORM set_config('my.p_end', current_end::text, true);
    
    RETURN QUERY
    SELECT * FROM formatted_tokens;
    
    current_start := current_end;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
-- WITH RECURSIVE params(p_start, p_end) AS (
--     SELECT 
--         CAST(current_setting('my.p_start', true) AS timestamptz),
--         CAST(current_setting('my.p_end', true) AS timestamptz)
-- ),
-- filtered_token_stats AS (
--     SELECT 
--         t.id AS token_id,
--         t.mint,
--         t.decimals,
--         t.name,
--         t.symbol,
--         t.platform,
--         tph.price,
--         tph.created_at
--     FROM token t
--     JOIN token_price_history tph ON t.id = tph.token
--     CROSS JOIN params
--     WHERE t.mint IS NOT NULL
--         AND tph.created_at >= params.p_start
-- ),
-- interval_stats AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         COUNT(*) AS trades,
--         first_value(price) OVER w AS latest_price,
--         first_value(price) OVER w_asc AS initial_price,
--         max(created_at) AS latest_created_at,
--         p_start AS interval_start
--     FROM filtered_token_stats
--     CROSS JOIN params
--     WHERE created_at <= p_end
--     GROUP BY 
--         token_id, mint, decimals, name, symbol, platform, price, created_at, p_start, p_end
--     WINDOW 
--         w AS (PARTITION BY mint ORDER BY created_at DESC),
--         w_asc AS (PARTITION BY mint ORDER BY created_at ASC)
-- ),
-- continuous_pump AS (
--     SELECT 
--         fs.token_id,
--         COUNT(*) AS trades_after,
--         MAX(fs.created_at) - i.latest_created_at AS pump_duration,
--         last_value(fs.price) OVER (
--             PARTITION BY fs.token_id 
--             ORDER BY fs.created_at
--             RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--         ) AS final_pump_price
--     FROM filtered_token_stats fs
--     JOIN interval_stats i ON fs.token_id = i.token_id
--     CROSS JOIN params
--     WHERE fs.created_at > params.p_end
--     AND fs.price > i.latest_price
--     GROUP BY fs.token_id, fs.mint, i.latest_created_at, i.latest_price, fs.price, fs.created_at
-- )
-- SELECT 
--     i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--     CASE
--         WHEN i.initial_price = 0 THEN 0::double precision
--         ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
--     END AS increase_pct,
--     CASE
--         WHEN i.latest_price = 0 THEN 0::double precision
--         ELSE ((COALESCE(cp.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
--     END AS increase_pct_after,
--     i.trades,
--     COALESCE(cp.trades_after, 0) AS trades_after,
--     COALESCE(cp.pump_duration, interval '0') AS pump_duration,
--     i.latest_created_at AS created_at,
--     i.interval_start
-- FROM interval_stats i
-- LEFT JOIN continuous_pump cp ON i.token_id = cp.token_id;

-- CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(
--     p_start timestamptz,
--     p_end timestamptz,
--     p_interval interval
-- )
-- RETURNS SETOF formatted_tokens_with_performance AS $$
-- DECLARE
--     current_start timestamptz;
--     current_end timestamptz;
-- BEGIN
--     current_start := p_start;
    
--     WHILE current_start < p_end LOOP
--         current_end := least(current_start + p_interval, p_end);
        
--         PERFORM set_config('my.p_start', current_start::text, true);
--         PERFORM set_config('my.p_end', current_end::text, true);
        
--         RETURN QUERY
--         SELECT * FROM formatted_tokens_with_performance;
        
--         current_start := current_end;
--     END LOOP;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
-- WITH RECURSIVE params(p_start, p_end) AS (
--     SELECT 
--         CAST(current_setting('my.p_start', true) AS timestamptz),
--         CAST(current_setting('my.p_end', true) AS timestamptz)
-- ),
-- filtered_token_stats AS (
--     SELECT 
--         t.id AS token_id,
--         t.mint,
--         t.decimals,
--         t.name,
--         t.symbol,
--         t.platform,
--         tph.price,
--         tph.created_at
--     FROM token t
--     JOIN token_price_history tph ON t.id = tph.token
--     CROSS JOIN params
--     WHERE t.mint IS NOT NULL
--         AND tph.created_at >= params.p_start
--         -- Add an upper bound to limit data fetched
--         AND tph.created_at <= params.p_end + interval '1 day'
-- ),
-- interval_stats AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         COUNT(*) AS trades,
--         first_value(price) OVER w AS latest_price,
--         first_value(price) OVER w_asc AS initial_price,
--         max(created_at) AS latest_created_at,
--         p_start AS interval_start
--     FROM filtered_token_stats
--     CROSS JOIN params
--     WHERE created_at <= p_end
--     GROUP BY 
--         token_id, mint, decimals, name, symbol, platform, price, created_at, p_start, p_end
--     WINDOW 
--         w AS (PARTITION BY mint ORDER BY created_at DESC),
--         w_asc AS (PARTITION BY mint ORDER BY created_at ASC)
-- ),
-- pump_prices AS (
--     SELECT 
--         fs.token_id,
--         fs.created_at,
--         fs.price,
--         i.latest_price AS interval_end_price,
--         i.latest_created_at AS interval_end_time
--     FROM filtered_token_stats fs
--     JOIN interval_stats i ON fs.token_id = i.token_id
--     WHERE fs.created_at > i.latest_created_at
--     AND fs.price > i.latest_price
-- ),
-- continuous_pump AS (
--     SELECT 
--         token_id,
--         COUNT(*) AS trades_after,
--         MAX(created_at) - MIN(interval_end_time) AS pump_duration,
--         MAX(price) AS final_pump_price
--     FROM pump_prices
--     GROUP BY token_id
-- )
-- SELECT 
--     i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--     CASE
--         WHEN i.initial_price = 0 THEN 0::double precision
--         ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
--     END AS increase_pct,
--     CASE
--         WHEN i.latest_price = 0 THEN 0::double precision
--         ELSE ((COALESCE(cp.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
--     END AS increase_pct_after,
--     i.trades,
--     COALESCE(cp.trades_after, 0) AS trades_after,
--     COALESCE(cp.pump_duration, interval '0') AS pump_duration,
--     i.latest_created_at AS created_at,
--     i.interval_start
-- FROM interval_stats i
-- LEFT JOIN continuous_pump cp ON i.token_id = cp.token_id;

-- CREATE  INDEX "token_price_history_price" on
--   "public"."token_price_history" using btree ("price");

-- CREATE  INDEX "token_price_history_token_created_at_index" on
--   "public"."token_price_history" using btree ("internal_token_transaction_ref", "token", "created_at");

-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
-- WITH RECURSIVE params(p_start, p_end) AS (
--     SELECT 
--         CAST(current_setting('my.p_start', true) AS timestamptz),
--         CAST(current_setting('my.p_end', true) AS timestamptz)
-- ),
-- filtered_token_stats AS (
--     SELECT 
--         t.id AS token_id,
--         t.mint,
--         t.decimals,
--         t.name,
--         t.symbol,
--         t.platform,
--         tph.price,
--         tph.created_at
--     FROM token t
--     JOIN token_price_history tph ON t.id = tph.token
--     CROSS JOIN params
--     WHERE t.mint IS NOT NULL
--         AND tph.created_at >= params.p_start
--         AND tph.created_at <= params.p_end + interval '1 day'
-- ),
-- interval_prices AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         price,
--         created_at,
--         p_start AS interval_start
--     FROM filtered_token_stats
--     CROSS JOIN params
--     WHERE created_at <= params.p_end
-- ),
-- interval_stats AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         COUNT(*) AS trades,
--         MAX(CASE WHEN created_at <= params.p_end THEN price END) AS latest_price,
--         MIN(CASE WHEN created_at <= params.p_end THEN price END) AS initial_price,
--         MAX(created_at) AS latest_created_at,
--         interval_start
--     FROM interval_prices
--     CROSS JOIN params
--     GROUP BY 
--         token_id, mint, decimals, name, symbol, platform, interval_start
-- ),
-- pump_stats AS (
--     SELECT 
--         fs.token_id,
--         COUNT(*) AS trades_after,
--         MAX(fs.created_at) - i.latest_created_at AS pump_duration,
--         MAX(fs.price) AS final_pump_price
--     FROM filtered_token_stats fs
--     JOIN interval_stats i ON fs.token_id = i.token_id
--     CROSS JOIN params
--     WHERE fs.created_at > params.p_end
--     AND fs.price > i.latest_price
--     GROUP BY fs.token_id, i.latest_created_at
-- )
-- SELECT 
--     i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--     CASE
--         WHEN i.initial_price = 0 THEN 0::double precision
--         ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
--     END AS increase_pct,
--     CASE
--         WHEN i.latest_price = 0 THEN 0::double precision
--         ELSE ((COALESCE(p.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
--     END AS increase_pct_after,
--     i.trades,
--     COALESCE(p.trades_after, 0) AS trades_after,
--     COALESCE(p.pump_duration, interval '0') AS pump_duration,
--     i.latest_created_at AS created_at,
--     i.interval_start
-- FROM interval_stats i
-- LEFT JOIN pump_stats p ON i.token_id = p.token_id;

-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
-- WITH RECURSIVE params(p_start, p_end) AS (
--     SELECT 
--         CAST(current_setting('my.p_start', true) AS timestamptz),
--         CAST(current_setting('my.p_end', true) AS timestamptz)
-- ),
-- filtered_token_stats AS (
--     SELECT 
--         t.id AS token_id,
--         t.mint,
--         t.decimals,
--         t.name,
--         t.symbol,
--         t.platform,
--         tph.price,
--         tph.created_at
--     FROM token t
--     JOIN token_price_history tph ON t.id = tph.token
--     CROSS JOIN params
--     WHERE t.mint IS NOT NULL
--         AND tph.created_at >= params.p_start
--         AND tph.created_at <= params.p_end + interval '1 day'
-- ),
-- interval_prices AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         price,
--         created_at,
--         p_start AS interval_start
--     FROM filtered_token_stats
--     CROSS JOIN params
--     WHERE created_at <= params.p_end
-- ),
-- interval_stats AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         COUNT(*) AS trades,
--         MAX(CASE WHEN created_at <= params.p_end THEN price END) AS latest_price,
--         MIN(CASE WHEN created_at <= params.p_end THEN price END) AS initial_price,
--         MAX(created_at) AS latest_created_at,
--         interval_start
--     FROM interval_prices
--     CROSS JOIN params
--     GROUP BY 
--         token_id, mint, decimals, name, symbol, platform, interval_start
-- ),
-- pump_stats AS (
--     SELECT 
--         fs.token_id,
--         COUNT(*) AS trades_after,
--         MAX(fs.created_at) - i.latest_created_at AS pump_duration,
--         MAX(fs.price) AS final_pump_price
--     FROM filtered_token_stats fs
--     JOIN interval_stats i ON fs.token_id = i.token_id
--     CROSS JOIN params
--     WHERE fs.created_at > params.p_end
--     AND fs.price > i.latest_price
--     GROUP BY fs.token_id, i.latest_created_at
-- )
-- SELECT 
--     i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--     CASE
--         WHEN i.initial_price = 0 THEN 0::double precision
--         ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
--     END AS increase_pct,
--     CASE
--         WHEN i.latest_price = 0 THEN 0::double precision
--         ELSE ((COALESCE(p.final_pump_price, i.latest_price) - i.latest_price) * 100 / i.latest_price)::double precision
--     END AS increase_pct_after,
--     i.trades,
--     COALESCE(p.trades_after, 0) AS trades_after,
--     COALESCE(p.pump_duration, interval '0') AS pump_duration,
--     i.latest_created_at AS created_at,
--     i.interval_start
-- FROM interval_stats i
-- LEFT JOIN pump_stats p ON i.token_id = p.token_id;

-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
--  WITH RECURSIVE params(p_start, p_end) AS (
--          SELECT (current_setting('my.p_start'::text, true))::timestamp with time zone AS current_setting,
--             (current_setting('my.p_end'::text, true))::timestamp with time zone AS current_setting
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
--           WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_start) AND (tph.created_at <= (params.p_end + '1 hour'::interval)))
--         ), interval_prices AS (
--          SELECT filtered_token_stats.token_id,
--             filtered_token_stats.mint,
--             filtered_token_stats.decimals,
--             filtered_token_stats.name,
--             filtered_token_stats.symbol,
--             filtered_token_stats.platform,
--             filtered_token_stats.price,
--             filtered_token_stats.created_at,
--             params.p_start AS interval_start
--            FROM (filtered_token_stats
--              CROSS JOIN params)
--           WHERE (filtered_token_stats.created_at <= params.p_end)
--         ), interval_stats AS (
--          SELECT interval_prices.token_id,
--             interval_prices.mint,
--             interval_prices.decimals,
--             interval_prices.name,
--             interval_prices.symbol,
--             interval_prices.platform,
--             count(*) AS trades,
--             max(
--                 CASE
--                     WHEN (interval_prices.created_at <= params.p_end) THEN interval_prices.price
--                     ELSE NULL::numeric
--                 END) AS latest_price,
--             min(
--                 CASE
--                     WHEN (interval_prices.created_at <= params.p_end) THEN interval_prices.price
--                     ELSE NULL::numeric
--                 END) AS initial_price,
--             max(interval_prices.created_at) AS latest_created_at,
--             interval_prices.interval_start
--            FROM (interval_prices
--              CROSS JOIN params)
--           GROUP BY interval_prices.token_id, interval_prices.mint, interval_prices.decimals, interval_prices.name, interval_prices.symbol, interval_prices.platform, interval_prices.interval_start
--         ), pump_stats AS (
--          SELECT fs.token_id,
--             count(*) AS trades_after,
--             (max(fs.created_at) - i_1.latest_created_at) AS pump_duration,
--             max(fs.price) AS final_pump_price
--            FROM ((filtered_token_stats fs
--              JOIN interval_stats i_1 ON ((fs.token_id = i_1.token_id)))
--              CROSS JOIN params)
--           WHERE ((fs.created_at > params.p_end) AND (fs.price > i_1.latest_price))
--           GROUP BY fs.token_id, i_1.latest_created_at
--         )
--  SELECT i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--         CASE
--             WHEN (i.initial_price = (0)::numeric) THEN (0)::double precision
--             ELSE ((((i.latest_price - i.initial_price) * (100)::numeric) / i.initial_price))::double precision
--         END AS increase_pct,
--         CASE
--             WHEN (i.latest_price = (0)::numeric) THEN (0)::double precision
--             ELSE ((((COALESCE(p.final_pump_price, i.latest_price) - i.latest_price) * (100)::numeric) / i.latest_price))::double precision
--         END AS increase_pct_after,
--     i.trades,
--     COALESCE(p.trades_after, (0)::bigint) AS trades_after,
--     COALESCE(p.pump_duration, '00:00:00'::interval) AS pump_duration,
--     i.latest_created_at AS created_at,
--     i.interval_start
--    FROM (interval_stats i
--      LEFT JOIN pump_stats p ON ((i.token_id = p.token_id)));

-- DROP FUNCTION "public"."get_formatted_tokens_with_performance_intervals_within_period"("pg_catalog"."timestamptz", "pg_catalog"."timestamptz", "pg_catalog"."interval");

-- DROP VIEW IF EXISTS "public"."formatted_tokens_with_performance";
-- CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
-- WITH RECURSIVE params(p_start, p_end, p_intervals) AS (
--     SELECT 
--         CAST(current_setting('my.p_start', true) AS timestamptz),
--         CAST(current_setting('my.p_end', true) AS timestamptz),
--         string_to_array(current_setting('my.p_intervals', true), ',')::interval[]
-- ),
-- intervals_expanded AS (
--     SELECT 
--         ordinality - 1 as interval_idx,
--         interval_value
--     FROM params,
--     unnest(p_intervals) WITH ORDINALITY AS t(interval_value, ordinality)
-- ),
-- max_interval AS (
--     SELECT max(interval_value) as max_interval FROM intervals_expanded
-- ),
-- filtered_token_stats AS (
--     SELECT 
--         t.id AS token_id,
--         t.mint,
--         t.decimals,
--         t.name,
--         t.symbol,
--         t.platform,
--         tph.price,
--         tph.created_at
--     FROM token t
--     JOIN token_price_history tph ON t.id = tph.token
--     CROSS JOIN params
--     CROSS JOIN max_interval
--     WHERE t.mint IS NOT NULL
--         AND tph.created_at >= params.p_start
--         AND tph.created_at <= params.p_end + max_interval
-- ),
-- interval_stats AS (
--     SELECT 
--         token_id,
--         mint,
--         decimals,
--         name,
--         symbol,
--         platform,
--         COUNT(*) AS trades,
--         MAX(CASE WHEN created_at <= params.p_end THEN price END) AS latest_price,
--         MIN(CASE WHEN created_at <= params.p_end THEN price END) AS initial_price,
--         MAX(created_at) FILTER (WHERE created_at <= params.p_end) AS latest_created_at,
--         p_start AS interval_start
--     FROM filtered_token_stats
--     CROSS JOIN params
--     GROUP BY 
--         token_id, mint, decimals, name, symbol, platform, p_start
-- ),
-- after_intervals AS (
--     SELECT 
--         i.token_id,
--         p.interval_idx,
--         p.interval_value,
--         COUNT(*) AS trades,
--         MIN(fs.price) FILTER (WHERE fs.created_at <= i.latest_created_at + p.interval_value) AS initial_price,
--         MAX(fs.price) FILTER (WHERE fs.created_at <= i.latest_created_at + p.interval_value) AS final_price
--     FROM interval_stats i
--     CROSS JOIN intervals_expanded p
--     JOIN filtered_token_stats fs ON i.token_id = fs.token_id
--     WHERE fs.created_at > i.latest_created_at
--         AND fs.created_at <= i.latest_created_at + p.interval_value
--     GROUP BY i.token_id, p.interval_idx, p.interval_value
-- )
-- SELECT 
--     i.token_id,
--     i.mint,
--     i.decimals,
--     i.name,
--     i.symbol,
--     i.platform,
--     i.latest_price,
--     CASE
--         WHEN i.initial_price = 0 THEN 0::double precision
--         ELSE ((i.latest_price - i.initial_price) * 100 / i.initial_price)::double precision
--     END AS increase_pct,
--     array_agg(ai.trades ORDER BY ai.interval_idx) FILTER (WHERE ai.trades IS NOT NULL) AS trades_after,
--     array_agg(
--         CASE
--             WHEN ai.initial_price = 0 THEN 0::double precision
--             ELSE ((ai.final_price - ai.initial_price) * 100 / ai.initial_price)::double precision
--         END ORDER BY ai.interval_idx
--     ) FILTER (WHERE ai.trades IS NOT NULL) AS increase_pct_after,
--     i.trades,
--     i.latest_created_at AS created_at,
--     i.interval_start
-- FROM interval_stats i
-- LEFT JOIN after_intervals ai ON i.token_id = ai.token_id
-- GROUP BY 
--     i.token_id, i.mint, i.decimals, i.name, i.symbol, i.platform, 
--     i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;

-- CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(
--     p_start timestamptz,
--     p_end timestamptz,
--     p_interval interval,
--     p_intervals interval[] DEFAULT ARRAY['1 minute'::interval]
-- )
-- RETURNS SETOF formatted_tokens_with_performance AS $$
-- DECLARE
--     current_start timestamptz;
--     current_end timestamptz;
-- BEGIN
--     current_start := p_start;
    
--     WHILE current_start < p_end LOOP
--         current_end := least(current_start + p_interval, p_end);
        
--         PERFORM set_config('my.p_start', current_start::text, true);
--         PERFORM set_config('my.p_end', current_end::text, true);
--         PERFORM set_config('my.p_intervals', array_to_string(p_intervals, ','), true);
        
--         RETURN QUERY
--         SELECT * FROM formatted_tokens_with_performance;
        
--         current_start := current_end;
--     END LOOP;
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP FUNCTION IF EXISTS public.get_formatted_tokens_with_performance_intervals_within_period CASCADE;
-- CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(p_start timestamp with time zone, p_end timestamp with time zone, p_interval interval, p_intervals text DEFAULT '1 minute')
--  RETURNS SETOF formatted_tokens_with_performance
--  LANGUAGE plpgsql
-- AS $function$
-- DECLARE
--     current_start timestamptz;
--     current_end timestamptz;
-- BEGIN
--     current_start := p_start;
    
--     WHILE current_start < p_end LOOP
--         current_end := least(current_start + p_interval, p_end);
        
--         PERFORM set_config('my.p_start', current_start::text, true);
--         PERFORM set_config('my.p_end', current_end::text, true);
--         PERFORM set_config('my.p_intervals', p_intervals, true);
        
--         RETURN QUERY
--         SELECT * FROM formatted_tokens_with_performance;
        
--         current_start := current_end;
--     END LOOP;
-- END;
-- $function$;

DROP FUNCTION IF EXISTS "public"."get_formatted_tokens_with_performance_intervals_within_period"("pg_catalog"."timestamptz", "pg_catalog"."timestamptz", "pg_catalog"."interval", "pg_catalog"."text") CASCADE;
DROP VIEW IF EXISTS "public"."formatted_tokens_with_performance" CASCADE;

CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
 WITH RECURSIVE params(p_start, p_end, p_intervals) AS (
         SELECT (current_setting('my.p_start'::text, true))::timestamp with time zone AS current_setting,
            (current_setting('my.p_end'::text, true))::timestamp with time zone AS current_setting,
            (string_to_array(current_setting('my.p_intervals'::text, true), ','::text))::interval[] AS string_to_array
        ), intervals_expanded AS (
         SELECT (t.ordinality - 1) AS interval_idx,
            t.interval_value
           FROM params,
            LATERAL unnest(params.p_intervals) WITH ORDINALITY t(interval_value, ordinality)
        ), max_interval AS (
         SELECT max(intervals_expanded.interval_value) AS max_interval
           FROM intervals_expanded
        ), filtered_token_stats AS (
         SELECT t.id AS token_id,
            t.mint,
            t.decimals,
            t.name,
            t.symbol,
            t.platform,
            tph.price,
            tph.created_at
           FROM (((token t
             JOIN token_price_history tph ON ((t.id = tph.token)))
             CROSS JOIN params)
             CROSS JOIN max_interval)
          WHERE ((t.mint IS NOT NULL) AND (tph.created_at >= params.p_start) AND (tph.created_at <= (params.p_end + max_interval.max_interval)))
        ), interval_stats AS (
         SELECT filtered_token_stats.token_id,
            filtered_token_stats.mint,
            filtered_token_stats.decimals,
            filtered_token_stats.name,
            filtered_token_stats.symbol,
            filtered_token_stats.platform,
            count(*) AS trades,
            max(
                CASE
                    WHEN (filtered_token_stats.created_at <= params.p_end) THEN filtered_token_stats.price
                    ELSE NULL::numeric
                END) AS latest_price,
            min(
                CASE
                    WHEN (filtered_token_stats.created_at <= params.p_end) THEN filtered_token_stats.price
                    ELSE NULL::numeric
                END) AS initial_price,
            max(filtered_token_stats.created_at) FILTER (WHERE (filtered_token_stats.created_at <= params.p_end)) AS latest_created_at,
            params.p_start AS interval_start
           FROM (filtered_token_stats
             CROSS JOIN params)
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.platform, params.p_start
        ), after_intervals AS (
         SELECT i_1.token_id,
            p.interval_idx,
            p.interval_value,
            count(*) AS trades,
            min(fs.price) FILTER (WHERE (fs.created_at <= (i_1.latest_created_at + p.interval_value))) AS initial_price,
            max(fs.price) FILTER (WHERE (fs.created_at <= (i_1.latest_created_at + p.interval_value))) AS final_price
           FROM ((interval_stats i_1
             CROSS JOIN intervals_expanded p)
             JOIN filtered_token_stats fs ON ((i_1.token_id = fs.token_id)))
          WHERE ((fs.created_at > i_1.latest_created_at) AND (fs.created_at <= (i_1.latest_created_at + p.interval_value)))
          GROUP BY i_1.token_id, p.interval_idx, p.interval_value
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
    (array_to_json(
        array_agg(ai.trades ORDER BY ai.interval_idx) FILTER (WHERE ai.trades IS NOT NULL)
    ))::text AS trades_after,
    (array_to_json(
        array_agg(
            CASE
                WHEN ai.initial_price = 0 THEN 0::double precision
                ELSE ((ai.final_price - ai.initial_price) * 100 / ai.initial_price)::double precision
            END ORDER BY ai.interval_idx
        ) FILTER (WHERE ai.trades IS NOT NULL)
    ))::text AS increase_pct_after,
    i.trades,
    i.latest_created_at AS created_at,
    i.interval_start
FROM interval_stats i
LEFT JOIN after_intervals ai ON i.token_id = ai.token_id
GROUP BY 
    i.token_id, i.mint, i.decimals, i.name, i.symbol, i.platform, 
    i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;

CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(p_start timestamp with time zone, p_end timestamp with time zone, p_interval interval, p_intervals text DEFAULT '1 minute'::text)
 RETURNS SETOF formatted_tokens_with_performance
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_start timestamptz;
    current_end timestamptz;
BEGIN
    current_start := p_start;
    
    WHILE current_start < p_end LOOP
        current_end := least(current_start + p_interval, p_end);
        
        PERFORM set_config('my.p_start', current_start::text, true);
        PERFORM set_config('my.p_end', current_end::text, true);
        PERFORM set_config('my.p_intervals', p_intervals, true);
        
        RETURN QUERY
        SELECT * FROM formatted_tokens_with_performance;
        
        current_start := current_end;
    END LOOP;
END;
$function$;
