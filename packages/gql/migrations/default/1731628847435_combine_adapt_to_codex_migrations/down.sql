
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP FUNCTION public.sell_token;
-- CREATE OR REPLACE FUNCTION public.sell_token(
--     user_wallet character varying,
--     token text,
--     amount_to_sell numeric,
--     token_cost numeric DEFAULT NULL::numeric
-- ) RETURNS token_transaction
-- LANGUAGE plpgsql AS $function$
-- DECLARE
--     total_proceeds NUMERIC;
--     token_balance NUMERIC;
--     wallet_transaction_id UUID;
--     token_txn token_transaction%ROWTYPE;
-- BEGIN
--     -- Acquire an advisory lock on the wallet
--     PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));
--
--     -- Use provided token cost
--     IF token_cost IS NULL THEN
--         RAISE EXCEPTION 'Token cost must be provided';
--     END IF;
--
--     -- Calculate total proceeds
--     total_proceeds := (token_cost * amount_to_sell) / CAST(1e9 AS NUMERIC);
--
--     -- Get token balance
--     SELECT COALESCE(SUM(amount), 0) INTO token_balance
--     FROM token_transaction
--     WHERE wallet_transaction IN (
--         SELECT id FROM wallet_transaction WHERE wallet_transaction.wallet = user_wallet
--     ) AND token = token;
--
--     -- Check if wallet has enough tokens to sell
--     IF token_balance < amount_to_sell THEN
--         RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
--     END IF;
--
--     -- Insert a new wallet_transaction for the proceeds (credit)
--     INSERT INTO wallet_transaction (wallet, amount)
--     VALUES (user_wallet, total_proceeds)
--     RETURNING id INTO wallet_transaction_id;
--
--     -- Insert a new token_transaction for the tokens sold (debit)
--     INSERT INTO token_transaction (token, amount, wallet_transaction)
--     VALUES (token, -amount_to_sell, wallet_transaction_id)
--     RETURNING * INTO token_txn;
--
--     RETURN token_txn;
-- END;
-- $function$;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP FUNCTION public.buy_token;
-- CREATE OR REPLACE FUNCTION public.buy_token(
--     user_wallet character varying,
--     token text,
--     amount_to_buy numeric,
--     token_cost numeric DEFAULT NULL::numeric
-- ) RETURNS token_transaction
-- LANGUAGE plpgsql AS $function$
-- DECLARE
--     total_cost NUMERIC;
--     wallet_balance NUMERIC;
--     wallet_transaction_id UUID;
--     token_txn token_transaction%ROWTYPE;
-- BEGIN
--     -- Lock the account to prevent concurrent transactions
--     PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));
--
--     -- Use provided token cost
--     IF token_cost IS NULL THEN
--         RAISE EXCEPTION 'Token cost must be provided';
--     END IF;
--
--     -- Calculate total cost
--     total_cost := (token_cost * amount_to_buy) / CAST(1e9 AS NUMERIC);
--
--     -- Get wallet balance
--     SELECT COALESCE(SUM(amount), 0) INTO wallet_balance
--     FROM wallet_transaction
--     WHERE wallet_transaction.wallet = user_wallet;
--
--     -- Check if wallet has enough balance
--     IF wallet_balance < total_cost THEN
--         RAISE EXCEPTION 'Insufficient balance. Required: %, Available: %', total_cost, wallet_balance;
--     END IF;
--
--     -- Insert a new wallet_transaction for the cost (debit)
--     INSERT INTO wallet_transaction (wallet, amount)
--     VALUES (user_wallet, -total_cost)
--     RETURNING id INTO wallet_transaction_id;
--
--     -- Insert a new token_transaction for the tokens (credit)
--     INSERT INTO token_transaction (token, amount, wallet_transaction)
--     VALUES (token, amount_to_buy, wallet_transaction_id)
--     RETURNING * INTO token_txn;
--
--     RETURN token_txn;
-- END;
-- $function$;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP FUNCTION public.buy_token;
-- CREATE OR REPLACE FUNCTION public.buy_token(
--     user_wallet character varying,
--     token text,
--     amount_to_buy numeric,
--     token_cost numeric DEFAULT NULL::numeric
-- ) RETURNS token_transaction
-- LANGUAGE plpgsql AS $function$
-- DECLARE
--     total_cost NUMERIC;
--     wallet_balance NUMERIC;
--     wallet_transaction_id UUID;
--     token_txn token_transaction%ROWTYPE;
-- BEGIN
--     -- Lock the account to prevent concurrent transactions
--     PERFORM pg_advisory_xact_lock(hashtext(user_wallet::text));
--
--     -- Use provided token cost
--     IF token_cost IS NULL THEN
--         RAISE EXCEPTION 'Token cost must be provided';
--     END IF;
--
--     -- Calculate total cost
--     total_cost := (token_cost * amount_to_buy) / CAST(1e9 AS NUMERIC);
--
--     -- Get wallet balance
--     SELECT COALESCE(SUM(amount), 0) INTO wallet_balance
--     FROM wallet_transaction
--     WHERE wallet_transaction.wallet = user_wallet;
--
--     -- Check if wallet has enough balance
--     IF wallet_balance < total_cost THEN
--         RAISE EXCEPTION 'Insufficient balance. Required: %, Available: %', total_cost, wallet_balance;
--     END IF;
--
--     -- Insert a new wallet_transaction for the cost (debit)
--     INSERT INTO wallet_transaction (wallet, amount)
--     VALUES (user_wallet, -total_cost)
--     RETURNING id INTO wallet_transaction_id;
--
--     -- Insert a new token_transaction for the tokens (credit)
--     INSERT INTO token_transaction (token, amount, wallet_transaction)
--     VALUES (token, amount_to_buy, wallet_transaction_id)
--     RETURNING * INTO token_txn;
--
--     RETURN token_txn;
-- END;
-- $function$;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."token";

alter table "public"."token_transaction"
  add constraint "token_transaction_token_fkey"
  foreign key ("token")
  references "public"."token"
  ("id") on update no action on delete cascade;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."token_price_history";

CREATE  INDEX "token_price_histroy_created_at_index" on
  "public"."token_price_history" using btree ("created_at");

CREATE  INDEX "token_price_history_token_index" on
  "public"."token_price_history" using btree ("token");

CREATE  INDEX "token_price_history_token_created_at_index" on
  "public"."token_price_history" using btree ("created_at", "internal_token_transaction_ref", "token");

CREATE  INDEX "token_price_history_price" on
  "public"."token_price_history" using btree ("price");

alter table "public"."token_price_history" add constraint "token_price_history_price_check" check (CHECK (price >= 0::numeric));

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP VIEW "public"."formatted_tokens";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP VIEW "public"."formatted_tokens_with_performance";

CREATE OR REPLACE FUNCTION public.upsert_tokens_and_price_history(tokens jsonb, price_history jsonb)
 RETURNS SETOF token
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Fast token upsert with minimal locking
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

    RETURN QUERY 
    SELECT * FROM token 
    WHERE mint IN (
        SELECT x.mint FROM jsonb_to_recordset(tokens) AS x(mint text)
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_formatted_tokens_with_performance_intervals_within_period(p_start timestamp with time zone, p_end timestamp with time zone, p_interval interval, p_intervals text DEFAULT '1 minute'::text)
 RETURNS SETOF formatted_tokens_with_performance
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_start timestamptz;
    current_end timestamptz;
BEGIN
    current_start := p_start;
    
    WHILE current_start < p_end LOOP
        current_end := least(current_start + p_interval, p_end);
        
        PERFORM set_config('my.p_start', current_start::text, true);
        PERFORM set_config('my.p_end', current_end::text, true);
        PERFORM set_config('my.p_intervals', p_intervals, true);
        
        RETURN QUERY
        SELECT * FROM formatted_tokens_with_performance;
        
        current_start := current_end;
    END LOOP;
END;
$function$;

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

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP VIEW "public"."hourly_new_tokens";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP VIEW "public"."hourly_swaps";
