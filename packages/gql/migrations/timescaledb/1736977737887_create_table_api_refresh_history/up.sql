CREATE TABLE "api"."refresh_history" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "success" boolean NOT NULL, PRIMARY KEY ("id") , UNIQUE ("id"));
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION api.refresh_token_rolling_stats_30min()
RETURNS api.refresh_history AS $$
DECLARE
    result api.refresh_history;
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY api.token_rolling_stats_30min;
    INSERT INTO api.refresh_history (success) 
    VALUES (true)
    RETURNING * INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;