/* @name GetTokenRecentPrices */
WITH params AS (
  SELECT 
    now() as p_end,
    now() - :interval::interval as p_start
)
SELECT
  token_mint,
  token_metadata,
  token_price_usd,
  volume_usd,
  created_at
FROM trade_history
CROSS JOIN params
WHERE token_mint = :tokenMint
  AND created_at >= p_start
  AND created_at < p_end
ORDER BY created_at DESC; 