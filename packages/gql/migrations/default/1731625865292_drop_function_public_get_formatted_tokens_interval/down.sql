CREATE OR REPLACE FUNCTION public.get_formatted_tokens_interval(interval_param interval)
 RETURNS SETOF formatted_tokens
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Set the time window based on the interval
    PERFORM set_config('my.p_end', now()::text, false);
    PERFORM set_config('my.p_start', (now() - interval_param)::text, false);
    
    -- Return the results from the view
    RETURN QUERY SELECT * FROM formatted_tokens;
END;
$function$;
