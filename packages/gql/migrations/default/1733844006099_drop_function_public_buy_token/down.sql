CREATE OR REPLACE FUNCTION public.buy_token(user_wallet character varying, token_address text, amount_to_buy numeric, token_price double precision)
 RETURNS token_transaction
 LANGUAGE plpgsql
AS $function$
DECLARE
    total_cost NUMERIC;
    wallet_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Lock the account to prevent concurrent transactions
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Calculate total cost
    total_cost := (token_price * amount_to_buy) / CAST(1e9 AS NUMERIC);

    -- Get wallet balance
    SELECT COALESCE(SUM(amount), 0) INTO wallet_balance
    FROM wallet_transaction
    WHERE wallet_transaction.wallet = user_wallet;

    -- Check if wallet has enough balance
    IF wallet_balance < total_cost THEN
        RAISE EXCEPTION 'Insufficient balance. Required: %, Available: %', total_cost, wallet_balance;
    END IF;

    -- Insert a new wallet_transaction for the cost (debit)
    INSERT INTO wallet_transaction (wallet, amount)
    VALUES (user_wallet, -total_cost)
    RETURNING id INTO wallet_transaction_id;

    -- Insert a new token_transaction for the tokens (credit)
    INSERT INTO token_transaction (token, amount, wallet_transaction, token_price)
    VALUES (token_address, amount_to_buy, wallet_transaction_id, token_price)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;
