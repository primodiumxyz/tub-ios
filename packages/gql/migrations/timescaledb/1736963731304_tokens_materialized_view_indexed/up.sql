CREATE INDEX ON api.token_stats_30m (mint, bucket DESC);
CREATE INDEX ON api.token_stats_30m (bucket DESC);
CREATE INDEX ON api.token_stats_30m (volume_usd_30m DESC);

CREATE INDEX ON api.token_stats_2m (mint, bucket DESC);
CREATE INDEX ON api.token_stats_2m (bucket DESC);

CREATE INDEX ON api.token_metadata (mint, bucket DESC);
CREATE INDEX ON api.token_metadata (bucket DESC);
