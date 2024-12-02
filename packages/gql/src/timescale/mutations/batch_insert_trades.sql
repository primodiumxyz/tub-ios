/* 
 * @name batchInsertTrades
 * @param trades JSONB
 * @returns TABLE(
 *   id UUID,
 *   token_mint TEXT,
 *   token_price_usd NUMERIC,
 *   volume_usd NUMERIC,
 *   token_metadata token_metadata,
 *   created_at TIMESTAMPTZ
 * )
*/
CREATE OR REPLACE FUNCTION batch_insert_trades(trades JSONB)
RETURNS SETOF trade_history AS $$
  INSERT INTO trade_history (
    token_mint,
    token_price_usd,
    volume_usd,
    token_metadata,
    created_at
  )
  SELECT 
    u.token_mint,
    u.token_price_usd::NUMERIC,
    u.volume_usd::NUMERIC,
    u.token_metadata::token_metadata,
    COALESCE(u.created_at::TIMESTAMPTZ, NOW())
  FROM jsonb_to_recordset(trades) AS u(
    token_mint TEXT,
    token_price_usd NUMERIC,
    volume_usd NUMERIC,
    token_metadata JSONB,
    created_at TIMESTAMPTZ
  )
  RETURNING *;
$$ LANGUAGE SQL VOLATILE; 