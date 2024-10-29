CREATE OR REPLACE VIEW "public"."formatted_tokens" AS 
 WITH latest_token_stats AS (
         SELECT DISTINCT ON (t.mint) t.id AS token_id,
            t.mint,
            t.name,
            t.symbol,
            t.platform,
            count(*) OVER (PARTITION BY t.mint) AS trades,
            first_value(tph.price) OVER (PARTITION BY t.mint ORDER BY tph.created_at DESC) AS latest_price,
            first_value(tph.price) OVER (PARTITION BY t.mint ORDER BY tph.created_at) AS initial_price,
            max(tph.created_at) OVER (PARTITION BY t.mint) AS latest_created_at
           FROM (token_price_history tph
             JOIN token t ON ((tph.token = t.id)))
          WHERE (t.mint IS NOT NULL)
          ORDER BY t.mint, tph.created_at DESC
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
