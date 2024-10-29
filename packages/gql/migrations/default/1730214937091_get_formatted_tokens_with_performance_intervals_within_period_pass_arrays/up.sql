CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(
    p_start timestamptz,
    p_end timestamptz,
    p_interval interval,
    p_intervals interval[] DEFAULT ARRAY['1 minute'::interval]
)
RETURNS SETOF formatted_tokens_with_performance AS $$
DECLARE
    current_start timestamptz;
    current_end timestamptz;
BEGIN
    current_start := p_start;
    
    WHILE current_start < p_end LOOP
        current_end := least(current_start + p_interval, p_end);
        
        PERFORM set_config('my.p_start', current_start::text, true);
        PERFORM set_config('my.p_end', current_end::text, true);
        PERFORM set_config('my.p_intervals', array_to_string(p_intervals, ','), true);
        
        RETURN QUERY
        SELECT * FROM formatted_tokens_with_performance;
        
        current_start := current_end;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
