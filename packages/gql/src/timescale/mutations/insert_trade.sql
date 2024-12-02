/* 
 * @name insertTrade
 * @param token_mint TEXT
 * @param token_price_usd NUMERIC
 * @param volume_usd NUMERIC
 * @param token_metadata JSONB
 * @returns TABLE(
 *   id UUID,
 *   created_at TIMESTAMPTZ,
 *   token_mint TEXT,
 *   token_price_usd NUMERIC,
 *   volume_usd NUMERIC,
 *   token_metadata token_metadata
 * )
*/
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