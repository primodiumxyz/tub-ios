/* @name InsertTrade */
CREATE OR REPLACE FUNCTION insert_trade(
  token_mint TEXT,
  token_price_usd NUMERIC,
  volume_usd NUMERIC,
  token_metadata JSONB
)
RETURNS SETOF trade_history AS $$
  INSERT INTO trade_history (
    token_mint,
    token_price_usd,
    volume_usd,
    token_metadata
  )
  VALUES (
    token_mint,
    token_price_usd,
    volume_usd,
    token_metadata::token_metadata
  )
  RETURNING *;
$$ LANGUAGE SQL VOLATILE; 