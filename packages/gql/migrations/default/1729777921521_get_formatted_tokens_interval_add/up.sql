CREATE OR REPLACE FUNCTION public.get_formatted_tokens_interval(p_interval interval)
 RETURNS SETOF formatted_tokens
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM set_config('my.p_start', (now() - p_interval)::text, true);
    PERFORM set_config('my.p_end', now()::text, true);
    RETURN QUERY
    SELECT *
    FROM formatted_tokens;
END;
$function$;
