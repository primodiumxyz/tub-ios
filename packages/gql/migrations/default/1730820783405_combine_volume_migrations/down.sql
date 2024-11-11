
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
            tph.created_at,
                CASE
                    WHEN (tph.amount_in IS NOT NULL) THEN ((tph.amount_in * tph.price) / (t.decimals)::numeric)
                    WHEN (tph.amount_out IS NOT NULL) THEN ((tph.amount_out * tph.price) / (t.decimals)::numeric)
                    ELSE (0)::numeric
                END AS trade_volume
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
            sum(
                CASE
                    WHEN (filtered_token_stats.created_at <= params.p_end) THEN filtered_token_stats.trade_volume
                    ELSE (0)::numeric
                END) AS volume,
            params.p_start AS interval_start
           FROM (filtered_token_stats
             CROSS JOIN params)
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.description, filtered_token_stats.uri, filtered_token_stats.mint_burnt, filtered_token_stats.freeze_burnt, filtered_token_stats.supply, filtered_token_stats.is_pump_token, params.p_start
        ), after_intervals AS (
         SELECT i_1.token_id,
            p.interval_idx,
            p.interval_value,
            count(*) AS trades,
            min(tph.price) FILTER (WHERE (tph.created_at <= (i_1.latest_created_at + p.interval_value))) AS initial_price,
            max(tph.price) FILTER (WHERE (tph.created_at <= (i_1.latest_created_at + p.interval_value))) AS final_price,
            sum(tph.price) AS volume_in_interval
           FROM ((interval_stats i_1
             CROSS JOIN intervals_expanded p)
             JOIN token_price_history tph ON ((i_1.token_id = tph.token)))
          WHERE ((tph.created_at > i_1.latest_created_at) AND (tph.created_at <= (i_1.latest_created_at + p.interval_value)))
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
    COALESCE(i.volume, (0)::numeric) AS volume,
    (array_to_json(array_agg(COALESCE(ai.volume_in_interval, (0)::numeric) ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS volume_after
   FROM (interval_stats i
     LEFT JOIN after_intervals ai ON ((i.token_id = ai.token_id)))
  GROUP BY i.token_id, i.mint, i.decimals, i.name, i.symbol, i.description, i.uri, i.mint_burnt, i.freeze_burnt, i.supply, i.is_pump_token, i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start, i.volume;

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
                    WHEN (tph.amount_in IS NOT NULL) THEN ((tph.amount_in * tph.price) / (t.decimals)::numeric)
                    WHEN (tph.amount_out IS NOT NULL) THEN ((tph.amount_out * tph.price) / (t.decimals)::numeric)
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
    COALESCE(latest_token_stats.volume, (0)::numeric) AS volume
   FROM latest_token_stats;

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
            sum(
                CASE
                    WHEN (filtered_token_stats.created_at <= params.p_end) THEN filtered_token_stats.price
                    ELSE (0)::numeric
                END) AS volume,
            params.p_start AS interval_start
           FROM (filtered_token_stats
             CROSS JOIN params)
          GROUP BY filtered_token_stats.token_id, filtered_token_stats.mint, filtered_token_stats.decimals, filtered_token_stats.name, filtered_token_stats.symbol, filtered_token_stats.description, filtered_token_stats.uri, filtered_token_stats.mint_burnt, filtered_token_stats.freeze_burnt, filtered_token_stats.supply, filtered_token_stats.is_pump_token, params.p_start
        ), after_intervals AS (
         SELECT i_1.token_id,
            p.interval_idx,
            p.interval_value,
            count(*) AS trades,
            min(tph.price) FILTER (WHERE (tph.created_at <= (i_1.latest_created_at + p.interval_value))) AS initial_price,
            max(tph.price) FILTER (WHERE (tph.created_at <= (i_1.latest_created_at + p.interval_value))) AS final_price,
            sum(tph.price) AS volume_in_interval
           FROM ((interval_stats i_1
             CROSS JOIN intervals_expanded p)
             JOIN token_price_history tph ON ((i_1.token_id = tph.token)))
          WHERE ((tph.created_at > i_1.latest_created_at) AND (tph.created_at <= (i_1.latest_created_at + p.interval_value)))
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
    COALESCE((i.volume), (0)::numeric) AS volume,
    (array_to_json(array_agg(COALESCE((ai.volume_in_interval), (0)::numeric) ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS volume_after
   FROM (interval_stats i
     LEFT JOIN after_intervals ai ON ((i.token_id = ai.token_id)))
  GROUP BY i.token_id, i.mint, i.decimals, i.name, i.symbol, i.description, i.uri, i.mint_burnt, i.freeze_burnt, i.supply, i.is_pump_token, i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start, i.volume;

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
DROP FUNCTION public.upsert_tokens_and_price_history;
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
    (1000000)::numeric AS volume,
    (array_to_json(array_agg(((1000000)::numeric * ((1)::numeric + (((ai.interval_idx + 1))::numeric * 0.1))) ORDER BY ai.interval_idx) FILTER (WHERE (ai.trades IS NOT NULL))))::text AS volume_after
   FROM (interval_stats i
     LEFT JOIN after_intervals ai ON ((i.token_id = ai.token_id)))
  GROUP BY i.token_id, i.mint, i.decimals, i.name, i.symbol, i.description, i.uri, i.mint_burnt, i.freeze_burnt, i.supply, i.is_pump_token, i.latest_price, i.initial_price, i.trades, i.latest_created_at, i.interval_start;
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
    (1000000)::numeric AS volume
   FROM latest_token_stats;