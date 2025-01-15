SELECT add_continuous_aggregate_policy('api.tokens',
    start_offset => INTERVAL '35 minutes',
    end_offset => INTERVAL '0 seconds',
    schedule_interval => INTERVAL '5 seconds'
);
