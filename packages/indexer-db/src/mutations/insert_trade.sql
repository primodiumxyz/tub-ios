/* @name InsertTrade */
INSERT INTO trade_history (
  token_mint,
  token_price_usd,
  volume_usd,
  token_metadata
) VALUES (
  :tokenMint,
  :tokenPriceUsd,
  :volumeUsd,
  :tokenMetadata
)
RETURNING *; 