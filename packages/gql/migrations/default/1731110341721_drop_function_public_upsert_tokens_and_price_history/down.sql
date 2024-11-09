CREATE OR REPLACE FUNCTION public.upsert_tokens_and_price_history(tokens jsonb, price_history jsonb)
 RETURNS SETOF token
 LANGUAGE plpgsql
AS $function$
DECLARE
    inserted_token token%ROWTYPE;
BEGIN
    -- For each token in the input jsonb, insert/update and return the token
    FOR inserted_token IN 
        INSERT INTO token (
            mint,
            name,
            symbol,
            description,
            uri,
            mint_burnt,
            freeze_burnt,
            supply,
            decimals,
            is_pump_token
        )
        SELECT 
            x.mint,
            x.name,
            x.symbol,
            x.description,
            x.uri,
            x.mint_burnt,
            x.freeze_burnt,
            (x.supply)::numeric,
            x.decimals,
            x.is_pump_token
        FROM jsonb_to_recordset(tokens) AS x(
            mint text,
            name text,
            symbol text,
            description text,
            uri text,
            mint_burnt boolean,
            freeze_burnt boolean,
            supply text,
            decimals int,
            is_pump_token boolean
        )
        ON CONFLICT (mint) 
        DO UPDATE SET
            name = EXCLUDED.name,
            symbol = EXCLUDED.symbol,
            description = EXCLUDED.description,
            uri = EXCLUDED.uri,
            mint_burnt = EXCLUDED.mint_burnt,
            freeze_burnt = EXCLUDED.freeze_burnt,
            supply = EXCLUDED.supply,
            decimals = EXCLUDED.decimals,
            is_pump_token = EXCLUDED.is_pump_token,
            updated_at = CURRENT_TIMESTAMP
        RETURNING *
    LOOP
        -- Insert price history for this token if it exists
        INSERT INTO token_price_history (
            token,
            price,
            amount_in,
            min_amount_out,
            max_amount_in,
            amount_out,
            created_at
        )
        SELECT 
            inserted_token.id,
            (p.price)::numeric,
            (p.amount_in)::numeric,
            (p.min_amount_out)::numeric,
            (p.max_amount_in)::numeric,
            (p.amount_out)::numeric,
            (p.created_at)::timestamptz
        FROM jsonb_to_recordset(price_history) AS p(
            mint text,
            price text,
            amount_in text,
            min_amount_out text,
            max_amount_in text,
            amount_out text,
            created_at timestamptz
        )
        WHERE p.mint = inserted_token.mint;
        
        RETURN NEXT inserted_token;
    END LOOP;
    
    RETURN;
END;
$function$;
