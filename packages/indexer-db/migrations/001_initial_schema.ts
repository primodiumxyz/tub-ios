/* eslint-disable @typescript-eslint/no-explicit-any */
exports.up = (pgm: any) => {
  // Enable TimescaleDB extension
  pgm.sql(`CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;`);

  // Create blocks table
  pgm.sql(`
    CREATE TABLE blocks (
      block_number BIGINT NOT NULL,
      block_timestamp TIMESTAMPTZ NOT NULL,
      block_hash TEXT NOT NULL,
      PRIMARY KEY (block_number, block_timestamp)
    );
    
    SELECT create_hypertable('blocks', 'block_timestamp');
  `);
};

exports.down = (pgm: any) => {
  pgm.sql(`DROP TABLE IF EXISTS blocks;`);
};
