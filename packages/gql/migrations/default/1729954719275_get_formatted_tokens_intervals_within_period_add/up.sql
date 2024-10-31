DROP FUNCTION IF EXISTS public.get_formatted_tokens_intervals_within_period(timestamptz, timestamptz, interval);
CREATE OR REPLACE FUNCTION public.get_formatted_tokens_intervals_within_period(
  p_start timestamptz,
  p_end timestamptz,
  p_interval interval
)
RETURNS SETOF formatted_tokens AS $$
DECLARE
  current_start timestamptz;
  current_end timestamptz;
BEGIN
  current_start := p_start;
  
  WHILE current_start < p_end LOOP
    current_end := least(current_start + p_interval, p_end);
    
    PERFORM set_config('my.p_start', current_start::text, true);
    PERFORM set_config('my.p_end', current_end::text, true);
    
    RETURN QUERY
    SELECT * FROM formatted_tokens;
    
    current_start := current_end;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
