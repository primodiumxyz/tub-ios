/* @name BatchInsertTrades */
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
FROM jsonb_to_recordset(:trades::jsonb) AS u(
  token_mint TEXT,
  token_price_usd NUMERIC,
  volume_usd NUMERIC,
  token_metadata jsonb
)
RETURNING *; 