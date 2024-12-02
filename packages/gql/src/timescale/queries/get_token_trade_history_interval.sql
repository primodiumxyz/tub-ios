/* 
 * @name getTokenTradeHistoryInterval
 * @param token_mint TEXT
 * @param interval_seconds INTEGER
 * @returns TABLE(
 *   id UUID,
 *   created_at TIMESTAMPTZ,
 *   token_mint TEXT,
 *   token_price_usd NUMERIC,
 *   volume_usd NUMERIC,
 *   token_metadata token_metadata
 * )
*/
CREATE OR REPLACE FUNCTION get_token_trade_history_interval(
  token_mint TEXT,
  interval_seconds INTEGER
)
RETURNS SETOF trade_history AS $$
  WITH params AS (
    SELECT 
      NOW() - (interval '1 second' * interval_seconds) as start_time,
      NOW() as end_time
  )
  SELECT 
    id,
    created_at,
    token_mint,
    token_price_usd,
    volume_usd,
    token_metadata
  FROM trade_history, params
  WHERE 
    token_mint = $1
    AND created_at >= params.start_time
    AND created_at <= params.end_time
  ORDER BY created_at DESC;
$$ LANGUAGE SQL STABLE; 