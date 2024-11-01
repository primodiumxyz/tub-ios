

alter table "public"."token" alter column "name" drop not null;

alter table "public"."token" alter column "symbol" drop not null;

alter table "public"."token" alter column "supply" drop not null;

alter table "public"."token" alter column "mint" set not null;

alter table "public"."token" add column "mint_burnt" boolean
 null default 'false';

alter table "public"."token" add column "freeze_burnt" boolean
 null default 'false';

alter table "public"."token" add column "is_pump_token" boolean
 null default 'false';

alter table "public"."token" add column "description" text
 null;

alter table "public"."token_price_history" add column "amount_in" int8
 null;

alter table "public"."token_price_history" add column "min_amount_out" int8
 null;

alter table "public"."token_price_history" add column "amount_out" int8
 null;

alter table "public"."token_price_history" add column "max_amount_in" int8
 null;

ALTER TABLE "public"."token_price_history" ALTER COLUMN "amount_in" TYPE numeric;

ALTER TABLE "public"."token_price_history" ALTER COLUMN "min_amount_out" TYPE numeric;

ALTER TABLE "public"."token_price_history" ALTER COLUMN "amount_out" TYPE numeric;

ALTER TABLE "public"."token_price_history" ALTER COLUMN "max_amount_in" TYPE numeric;

DROP FUNCTION "public"."get_formatted_tokens"("pg_catalog"."timestamptz");

DROP VIEW "public"."formatted_tokens" CASCADE;
CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
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
        t.description,
        t.uri,
        t.mint_burnt,
        t.freeze_burnt,
        t.supply,
        t.is_pump_token,
        tph.price,
        tph.created_at
    FROM token t
    JOIN token_price_history tph ON t.id = tph.token
    CROSS JOIN params
    WHERE t.mint IS NOT NULL
        AND tph.created_at >= params.p_start
        AND tph.created_at <= params.p_end
),
latest_token_stats AS (
    SELECT DISTINCT ON (filtered_token_stats.mint)
        filtered_token_stats.token_id,
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
        first_value(filtered_token_stats.price) OVER (PARTITION BY filtered_token_stats.mint ORDER BY filtered_token_stats.created_at ASC) AS initial_price,
        max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at
    FROM filtered_token_stats
    ORDER BY filtered_token_stats.mint, filtered_token_stats.created_at DESC
)
SELECT 
    latest_token_stats.token_id,
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
    latest_token_stats.latest_created_at AS created_at
FROM latest_token_stats;

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
            tph.created_at
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
            max(filtered_token_stats.created_at) OVER (PARTITION BY filtered_token_stats.mint) AS latest_created_at
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
    1000000::numeric AS volume  -- TODO: implement volume calculation
   FROM latest_token_stats;

CREATE OR REPLACE FUNCTION get_formatted_tokens_interval(interval_param interval)
RETURNS SETOF formatted_tokens AS $$
BEGIN
    -- Set the time window based on the interval
    PERFORM set_config('my.p_end', now()::text, false);
    PERFORM set_config('my.p_start', (now() - interval_param)::text, false);
    
    -- Return the results from the view
    RETURN QUERY SELECT * FROM formatted_tokens;
END;
$$ LANGUAGE plpgsql;

DROP VIEW "public"."formatted_tokens_with_performance" CASCADE;
CREATE OR REPLACE VIEW "public"."formatted_tokens_with_performance" AS 
WITH RECURSIVE params(p_start, p_end, p_intervals) AS (
    SELECT 
        CAST(current_setting('my.p_start', true) AS timestamptz),
        CAST(current_setting('my.p_end', true) AS timestamptz),
        string_to_array(current_setting('my.p_intervals', true), ',')::interval[]
), intervals_expanded AS (
    SELECT 
        ordinality - 1 as interval_idx,
        interval_value
    FROM params,
    unnest(p_intervals) WITH ORDINALITY AS t(interval_value, ordinality)
), max_interval AS (
    SELECT max(interval_value) as max_interval FROM intervals_expanded
), filtered_token_stats AS (
    SELECT 
        t.id AS token_id,
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
        tph.created_at
    FROM token t
    JOIN token_price_history tph ON t.id = tph.token
    CROSS JOIN params
    CROSS JOIN max_interval
    WHERE t.mint IS NOT NULL
        AND tph.created_at >= params.p_start 
        AND tph.created_at <= params.p_end + max_interval.max_interval
), interval_stats AS (
    SELECT 
        token_id,
        mint,
        decimals,
        name,
        symbol,
        description,
        uri,
        mint_burnt,
        freeze_burnt,
        supply,
        is_pump_token,
        COUNT(*) AS trades,
        MAX(CASE WHEN created_at <= params.p_end THEN price END) AS latest_price,
        MIN(CASE WHEN created_at <= params.p_end THEN price END) AS initial_price,
        MAX(created_at) FILTER (WHERE created_at <= params.p_end) AS latest_created_at,
        p_start AS interval_start
    FROM filtered_token_stats
    CROSS JOIN params
    GROUP BY 
        token_id, mint, decimals, name, symbol, description, uri,
        mint_burnt, freeze_burnt, supply, is_pump_token, p_start
), after_intervals AS (
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
    i.description,
    i.uri,
    i.mint_burnt,
    i.freeze_burnt,
    i.supply,
    i.is_pump_token,
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
    i.interval_start,
    1000000::numeric AS volume
FROM interval_stats i
LEFT JOIN after_intervals ai ON i.token_id = ai.token_id
GROUP BY 
    i.token_id, i.mint, i.decimals, i.name, i.symbol, i.description, i.uri,
    i.mint_burnt, i.freeze_burnt, i.supply, i.is_pump_token,
    i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;

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
            t.description,
            t.uri,
            t.mint_burnt,
            t.freeze_burnt,
            t.supply,
            t.is_pump_token,
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
            filtered_token_stats.description,
            filtered_token_stats.uri,
            filtered_token_stats.mint_burnt,
            filtered_token_stats.freeze_burnt,
            filtered_token_stats.supply,
            filtered_token_stats.is_pump_token,
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
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.description, filtered_token_stats.uri, filtered_token_stats.mint_burnt, filtered_token_stats.freeze_burnt, filtered_token_stats.supply, filtered_token_stats.is_pump_token, params.p_start
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
 SELECT i.token_id,
    i.mint,
    i.decimals,
    i.name,
    i.symbol,
    i.description,
    i.uri,
    i.mint_burnt,
    i.freeze_burnt,
    i.supply,
    i.is_pump_token,
    i.latest_price,
        CASE
            WHEN (i.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((i.latest_price - i.initial_price) * (100)::numeric) / i.initial_price))::double precision
        END AS increase_pct,
    (array_to_json(array_agg(ai.trades ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS trades_after,
    (array_to_json(array_agg(
        CASE
            WHEN (ai.initial_price = (0)::numeric) THEN (0)::double precision
            ELSE ((((ai.final_price - ai.initial_price) * (100)::numeric) / ai.initial_price))::double precision
        END ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS increase_pct_after,
    i.trades,
    i.latest_created_at AS created_at,
    i.interval_start,
    -- fake volume and volume_after
    (1000000)::numeric AS volume,
    (array_to_json(array_agg(
        1000000 * (1 + (ai.interval_idx + 1) * 0.1)
        ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS volume_after
   FROM (interval_stats i
     LEFT JOIN after_intervals ai ON ((i.token_id = ai.token_id)))
  GROUP BY i.token_id, i.mint, i.decimals, i.name, i.symbol, i.description, i.uri, i.mint_burnt, i.freeze_burnt, i.supply, i.is_pump_token, i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;

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
