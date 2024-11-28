/* eslint-disable @typescript-eslint/no-explicit-any */
exports.up = (pgm: any) => {
  // Enable TimescaleDB extension
  pgm.sql(`CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;`);

  // Create the token metadata type
  pgm.sql(`
    CREATE TYPE token_metadata AS (
      name VARCHAR(255),
      symbol VARCHAR(10),
      description TEXT,
      image_uri TEXT,
      external_url TEXT,
      supply NUMERIC,
      is_pump_token BOOLEAN
    );
  `);

  // Create trade_history table optimized for time-series
  pgm.sql(`
    CREATE TABLE trade_history (
      id uuid NOT NULL DEFAULT gen_random_uuid(),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      token_mint TEXT NOT NULL,
      token_price_usd NUMERIC NOT NULL,
      volume_usd NUMERIC NOT NULL,
      token_metadata token_metadata NOT NULL,
      PRIMARY KEY (created_at, token_mint, id)
    );

    -- Convert to hypertable with 1-hour chunks for better query performance
    -- on 5-30 minute intervals
    SELECT create_hypertable('trade_history', 'created_at', 
      chunk_time_interval => INTERVAL '1 hour'
    );

    CREATE INDEX trade_history_token_mint_idx ON trade_history (token_mint, created_at DESC);

    -- Compress data older than 1 day since we mainly query recent data
    ALTER TABLE trade_history SET (
      timescaledb.compress,
      timescaledb.compress_segmentby = 'token_mint'
    );

    SELECT add_compression_policy('trade_history', INTERVAL '1 day');

    -- Create continuous aggregates at 5-minute intervals
    -- This helps with quick lookups for common interval queries
    CREATE MATERIALIZED VIEW trade_history_5min
    WITH (timescaledb.continuous) AS
    SELECT
      time_bucket('5 minutes', created_at) AS bucket,
      token_mint,
      FIRST(token_metadata, created_at) as token_metadata,
      AVG(token_price_usd) as avg_price,
      SUM(volume_usd) as total_volume,
      COUNT(*) as trade_count
    FROM trade_history
    GROUP BY bucket, token_mint
    WITH NO DATA;

    -- Refresh every 5 minutes, keeping last 24 hours of detailed data
    SELECT add_continuous_aggregate_policy('trade_history_5min',
      start_offset => INTERVAL '24 hours',
      end_offset => INTERVAL '5 minutes',
      schedule_interval => INTERVAL '5 minutes'
    );

    COMMENT ON TABLE trade_history IS 'History of trades on subscribed accounts from the indexer.';
  `);
};

exports.down = (pgm: any) => {
  pgm.sql(`
    DROP MATERIALIZED VIEW IF EXISTS trade_history_5min CASCADE;
    DROP TABLE IF EXISTS trade_history CASCADE;
    DROP TYPE IF EXISTS token_metadata CASCADE;
  `);
};
