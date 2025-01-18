
DROP FUNCTION api.refresh_token_rolling_stats_30min();
DROP TABLE "api"."refresh_history";
DROP MATERIALIZED VIEW IF EXISTS api.token_rolling_stats_30min;