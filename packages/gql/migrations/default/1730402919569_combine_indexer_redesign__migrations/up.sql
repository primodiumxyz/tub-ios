
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
