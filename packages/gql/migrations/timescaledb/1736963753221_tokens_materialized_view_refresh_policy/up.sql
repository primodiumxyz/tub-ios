-- Refresh policies
SELECT add_continuous_aggregate_policy('api.token_metadata',
    start_offset => INTERVAL '30 minutes', -- buffer as we need an updated supply for tokens we show from the top by volume
    end_offset => INTERVAL '0 seconds',
    schedule_interval => INTERVAL '5 seconds'
);

SELECT add_continuous_aggregate_policy('api.token_stats_30m',
    start_offset => INTERVAL '35 minutes', -- buffer for data corrections, e.g. when a token gets out of the 30min window
    end_offset => INTERVAL '0 seconds',
    schedule_interval => INTERVAL '5 seconds'
);

SELECT add_continuous_aggregate_policy('api.token_stats_2m',
    start_offset => INTERVAL '5 minutes', -- buffer for data corrections
    end_offset => INTERVAL '0 seconds',
    schedule_interval => INTERVAL '5 seconds'
);