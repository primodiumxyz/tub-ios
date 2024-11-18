

DROP VIEW "public"."hourly_swaps";

DROP VIEW "public"."hourly_new_tokens";

DROP FUNCTION "public"."get_formatted_tokens_interval"("pg_catalog"."interval");

DROP FUNCTION "public"."get_formatted_tokens_with_performance_intervals_within_period"("pg_catalog"."timestamptz", "pg_catalog"."timestamptz", "pg_catalog"."interval", "pg_catalog"."text");

DROP FUNCTION "public"."upsert_tokens_and_price_history"("pg_catalog"."jsonb", "pg_catalog"."jsonb");

DROP VIEW "public"."formatted_tokens_with_performance";

DROP VIEW "public"."formatted_tokens";

alter table "public"."token_price_history" drop constraint "token_price_history_price_check";

DROP INDEX IF EXISTS "public"."token_price_history_price";

DROP INDEX IF EXISTS "public"."token_price_history_token_created_at_index";

DROP INDEX IF EXISTS "public"."token_price_history_token_index";

DROP INDEX IF EXISTS "public"."token_price_histroy_created_at_index";

DROP table "public"."token_price_history";

alter table "public"."token_transaction" drop constraint "token_transaction_token_fkey";
alter table public.token_transaction alter column token type text;

DROP table "public"."token";

DROP FUNCTION public.buy_token;
CREATE OR REPLACE FUNCTION public.buy_token(
    user_wallet character varying,
    token text,
    amount_to_buy numeric,
    token_cost numeric DEFAULT NULL::numeric
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
DECLARE
    total_cost NUMERIC;
    wallet_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Lock the account to prevent concurrent transactions
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Use provided token cost
    IF token_cost IS NULL THEN
        RAISE EXCEPTION 'Token cost must be provided';
    END IF;

    -- Calculate total cost
    total_cost := (token_cost * amount_to_buy) / CAST(1e9 AS NUMERIC);

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
    INSERT INTO token_transaction (token, amount, wallet_transaction)
    VALUES (token, amount_to_buy, wallet_transaction_id)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;

DROP FUNCTION public.buy_token;
CREATE OR REPLACE FUNCTION public.buy_token(
    user_wallet character varying,
    token text,
    amount_to_buy numeric,
    token_cost numeric DEFAULT NULL::numeric
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
DECLARE
    total_cost NUMERIC;
    wallet_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Lock the account to prevent concurrent transactions
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Use provided token cost
    IF token_cost IS NULL THEN
        RAISE EXCEPTION 'Token cost must be provided';
    END IF;

    -- Calculate total cost
    total_cost := (token_cost * amount_to_buy) / CAST(1e9 AS NUMERIC);

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
    INSERT INTO token_transaction (token, amount, wallet_transaction)
    VALUES (token, amount_to_buy, wallet_transaction_id)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;

DROP FUNCTION public.sell_token;
CREATE OR REPLACE FUNCTION public.sell_token(
    user_wallet character varying,
    token text,
    amount_to_sell numeric,
    token_cost numeric DEFAULT NULL::numeric
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
DECLARE
    total_proceeds NUMERIC;
    token_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Acquire an advisory lock on the wallet
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Use provided token cost
    IF token_cost IS NULL THEN
        RAISE EXCEPTION 'Token cost must be provided';
    END IF;

    -- Calculate total proceeds
    total_proceeds := (token_cost * amount_to_sell) / CAST(1e9 AS NUMERIC);

    -- Get token balance
    SELECT COALESCE(SUM(amount), 0) INTO token_balance
    FROM token_transaction
    WHERE wallet_transaction IN (
        SELECT id FROM wallet_transaction WHERE wallet_transaction.wallet = user_wallet
    ) AND token = token;

    -- Check if wallet has enough tokens to sell
    IF token_balance < amount_to_sell THEN
        RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
    END IF;

    -- Insert a new wallet_transaction for the proceeds (credit)
    INSERT INTO wallet_transaction (wallet, amount)
    VALUES (user_wallet, total_proceeds)
    RETURNING id INTO wallet_transaction_id;

    -- Insert a new token_transaction for the tokens sold (debit)
    INSERT INTO token_transaction (token, amount, wallet_transaction)
    VALUES (token, -amount_to_sell, wallet_transaction_id)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;

alter table "public"."token_transaction" add column "token_price" double precision
 not null;

DROP FUNCTION public.buy_token;
CREATE OR REPLACE FUNCTION public.buy_token(
    user_wallet character varying,
    token text,
    amount_to_buy numeric,
    token_price double precision
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
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
    VALUES (token, amount_to_buy, wallet_transaction_id, token_price)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;
DROP FUNCTION public.sell_token;
CREATE OR REPLACE FUNCTION public.sell_token(
    user_wallet character varying,
    token text,
    amount_to_sell numeric,
    token_price double precision
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
DECLARE
    total_proceeds NUMERIC;
    token_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Acquire an advisory lock on the wallet
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Calculate total proceeds
    total_proceeds := (token_price * amount_to_sell) / CAST(1e9 AS NUMERIC);

    -- Get token balance
    SELECT COALESCE(SUM(amount), 0) INTO token_balance
    FROM token_transaction
    WHERE wallet_transaction IN (
        SELECT id FROM wallet_transaction WHERE wallet_transaction.wallet = user_wallet
    ) AND token = token;

    -- Check if wallet has enough tokens to sell
    IF token_balance < amount_to_sell THEN
        RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
    END IF;

    -- Insert a new wallet_transaction for the proceeds (credit)
    INSERT INTO wallet_transaction (wallet, amount)
    VALUES (user_wallet, total_proceeds)
    RETURNING id INTO wallet_transaction_id;

    -- Insert a new token_transaction for the tokens sold (debit)
    INSERT INTO token_transaction (token, amount, wallet_transaction, token_price)
    VALUES (token, -amount_to_sell, wallet_transaction_id, token_price)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;
DROP FUNCTION public.buy_token;
CREATE OR REPLACE FUNCTION public.buy_token(
    user_wallet character varying,
    token_address text,  -- renamed parameter to match sell_token
    amount_to_buy numeric,
    token_price double precision
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
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

DROP FUNCTION public.sell_token;
CREATE OR REPLACE FUNCTION public.sell_token(
    user_wallet character varying,
    token_address text,  -- renamed parameter to avoid ambiguity
    amount_to_sell numeric,
    token_price double precision
) RETURNS token_transaction
LANGUAGE plpgsql AS $function$
DECLARE
    total_proceeds NUMERIC;
    token_balance NUMERIC;
    wallet_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Acquire an advisory lock on the wallet
    PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));

    -- Calculate total proceeds
    total_proceeds := (token_price * amount_to_sell) / CAST(1e9 AS NUMERIC);

    -- Get token balance
    SELECT COALESCE(SUM(amount), 0) INTO token_balance
    FROM token_transaction
    WHERE wallet_transaction IN (
        SELECT id FROM wallet_transaction WHERE wallet_transaction.wallet = user_wallet
    ) AND token = token_address;  -- use the renamed parameter

    -- Check if wallet has enough tokens to sell
    IF token_balance < amount_to_sell THEN
        RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
    END IF;

    -- Insert a new wallet_transaction for the proceeds (credit)
    INSERT INTO wallet_transaction (wallet, amount)
    VALUES (user_wallet, total_proceeds)
    RETURNING id INTO wallet_transaction_id;

    -- Insert a new token_transaction for the tokens sold (debit)
    INSERT INTO token_transaction (token, amount, wallet_transaction, token_price)
    VALUES (token_address, -amount_to_sell, wallet_transaction_id, token_price)
    RETURNING * INTO token_txn;

    RETURN token_txn;
END;
$function$;
