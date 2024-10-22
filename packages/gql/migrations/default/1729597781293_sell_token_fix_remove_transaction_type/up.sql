CREATE OR REPLACE FUNCTION public.sell_token(account_id uuid, token_id uuid, amount_to_sell numeric, token_cost numeric DEFAULT NULL::numeric)
 RETURNS token_transaction
 LANGUAGE plpgsql
AS $function$
DECLARE
    latest_price NUMERIC(21,0);
    total_proceeds NUMERIC(21,0);
    token_balance NUMERIC(21,0);
    account_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Acquire an advisory lock on the account_id
    PERFORM pg_advisory_xact_lock(hashtext(account_id::text));
    -- Determine the latest price
    IF token_cost IS NOT NULL THEN
        latest_price := token_cost;
    ELSE
        -- Get the latest price of the token
        SELECT price INTO latest_price
        FROM token_price_history
        WHERE token = token_id
        ORDER BY created_at DESC
        LIMIT 1;
        IF latest_price IS NULL THEN
            RAISE EXCEPTION 'Token price not found for token_id %', token_id;
        END IF;
    END IF;
    -- Calculate total proceeds
    total_proceeds := latest_price/CAST(1e9 as numeric) * amount_to_sell;
    -- Adjust total proceeds with the balance multiplier
    total_proceeds := total_proceeds;
    -- Get token balance (tokens acquired)
    SELECT COALESCE(SUM(amount), 0) INTO token_balance
    FROM token_transaction
    WHERE account_transaction IN (
        SELECT id FROM account_transaction WHERE account = account_id
    ) AND token = token_id;
    -- Check if account has enough tokens to sell
    IF token_balance < amount_to_sell THEN
        RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
    END IF;
    -- Insert a new account_transaction for the proceeds (credit)
    INSERT INTO account_transaction (account, amount)
    VALUES (account_id, total_proceeds)
    RETURNING id INTO account_transaction_id;
    -- Insert a new token_transaction for the tokens sold (debit)
    INSERT INTO token_transaction (token, amount, account_transaction)
    VALUES (token_id, -amount_to_sell, account_transaction_id)
    RETURNING * INTO token_txn;
    -- Insert a new record into token_price_history
    INSERT INTO token_price_history (token, price, internal_token_transaction_ref)
    VALUES (token_id, latest_price, token_txn.id);
    -- Return the token_transaction record
    RETURN token_txn;
END;
$function$;
