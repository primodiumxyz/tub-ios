CREATE OR REPLACE VIEW hourly_swaps AS
SELECT
  date_trunc('hour', created_at) AS hour,
  COUNT(*) AS count
FROM
  token_price_history
GROUP BY
  date_trunc('hour', created_at)
ORDER BY
  hour;

CREATE OR REPLACE VIEW hourly_new_tokens AS
SELECT
  date_trunc('hour', created_at) AS hour,
  COUNT(*) AS count
FROM
  token
GROUP BY
  date_trunc('hour', created_at)
ORDER BY
  hour;
