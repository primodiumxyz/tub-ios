-- _UP_ (do not remove this comment)
CREATE TYPE trade_history_candle AS (
  bucket TIMESTAMPTZ,
  token_mint TEXT,
  open_price_usd NUMERIC,
  close_price_usd NUMERIC,
  high_price_usd NUMERIC,
  low_price_usd NUMERIC,
  volume_usd NUMERIC,
  token_metadata token_metadata
);

CREATE TYPE token_volume_stats AS (
  token_mint TEXT,
  token_metadata token_metadata,
  total_volume_usd NUMERIC,
  price_change_pct NUMERIC,
  avg_price_usd NUMERIC
);

-- _DOWN_ (do not remove this comment)
DROP TYPE trade_history_candle;
DROP TYPE token_volume_stats;
