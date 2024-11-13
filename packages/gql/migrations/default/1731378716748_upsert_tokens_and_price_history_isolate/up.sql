CREATE OR REPLACE FUNCTION public.upsert_tokens_and_price_history(
    tokens jsonb,
    price_history jsonb
) RETURNS SETOF token AS $$
DECLARE
    batch_id text;
BEGIN    
    -- Generate a unique batch ID for this operation
    batch_id := gen_random_uuid()::text;

    -- First, acquire locks on ALL affected tokens in a consistent order
    PERFORM t.mint 
    FROM jsonb_to_recordset(tokens) AS x(mint text)
    JOIN token t ON t.mint = x.mint
    ORDER BY t.mint -- Consistent ordering is key to prevent deadlocks
    FOR UPDATE;
    
    -- Now do the token upsert
    WITH inserted_tokens AS (
        INSERT INTO token (
            mint, name, symbol, description, uri, 
            mint_burnt, freeze_burnt, supply, decimals, is_pump_token
        )
        SELECT 
            x.mint, x.name, x.symbol, x.description, x.uri,
            x.mint_burnt, x.freeze_burnt, (x.supply)::numeric,
            x.decimals, x.is_pump_token
        FROM jsonb_to_recordset(tokens) AS x(
            mint text, name text, symbol text, description text,
            uri text, mint_burnt boolean, freeze_burnt boolean,
            supply text, decimals integer, is_pump_token boolean
        )
        ON CONFLICT (mint) DO UPDATE SET
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
        RETURNING id, mint
    )
    -- Insert price histories
    INSERT INTO token_price_history (
        token, price, amount_in, min_amount_out,
        max_amount_in, amount_out, created_at
    )
    SELECT 
        t.id,
        (p.price)::numeric,
        (p.amount_in)::numeric,
        (p.min_amount_out)::numeric,
        (p.max_amount_in)::numeric,
        (p.amount_out)::numeric,
        p.created_at
    FROM jsonb_to_recordset(price_history) AS p(
        mint text, price text, amount_in text,
        min_amount_out text, max_amount_in text,
        amount_out text, created_at timestamptz
    )
    JOIN inserted_tokens t ON t.mint = p.mint;

    -- Return the updated tokens
    RETURN QUERY 
    SELECT * FROM token 
    WHERE mint IN (
        SELECT x.mint FROM jsonb_to_recordset(tokens) AS x(mint text)
    );
END;
$$ LANGUAGE plpgsql;