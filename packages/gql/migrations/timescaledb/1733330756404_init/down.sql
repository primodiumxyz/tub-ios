DROP MATERIALIZED VIEW IF EXISTS api.trade_history_1min CASCADE;
DROP TABLE IF EXISTS api.trade_history CASCADE;
DROP TYPE IF EXISTS token_metadata CASCADE;
DROP SCHEMA IF EXISTS api CASCADE;
DROP EXTENSION IF EXISTS timescaledb CASCADE;

