CREATE OR REPLACE FUNCTION get_formatted_tokens(p_since timestamptz)
RETURNS SETOF formatted_tokens AS $$
BEGIN
    PERFORM set_config('my.p_since', p_since::text, true);
    RETURN QUERY
    SELECT *
    FROM formatted_tokens;
END;
$$ LANGUAGE plpgsql;
