/* @name BatchInsertTrades */
CREATE OR REPLACE FUNCTION batch_insert_trades(trades JSONB)
RETURNS SETOF trade_history AS $$
  INSERT INTO trade_history (
    token_mint,
    token_price_usd,
    volume_usd,
    token_metadata
  )
  SELECT 
    u.token_mint,
    u.token_price_usd,
    u.volume_usd,
    u.token_metadata::token_metadata
  FROM jsonb_to_recordset(trades) AS u(
    token_mint TEXT,
    token_price_usd NUMERIC,
    volume_usd NUMERIC,
    token_metadata jsonb
  )
  -- TimescaleDB will automatically handle chunk routing and index updates
  RETURNING *;
$$ LANGUAGE SQL VOLATILE; 