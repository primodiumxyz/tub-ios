CREATE OR REPLACE FUNCTION public.get_formatted_tokens(p_since timestamp with time zone)
RETURNS SETOF formatted_tokens
LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM set_config('my.p_start', p_since::text, true);
    PERFORM set_config('my.p_end', now()::text, true);
    RETURN QUERY
    SELECT *
    FROM formatted_tokens;
END;
$function$;
