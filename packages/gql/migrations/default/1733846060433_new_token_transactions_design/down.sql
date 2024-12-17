
alter table "public"."token_sale" alter column "source" set not null;

alter table "public"."token_sale" alter column "build" set not null;

alter table "public"."token_purchase" alter column "build" set not null;

alter table "public"."token_purchase" alter column "source" set not null;

DROP INDEX IF EXISTS "public"."token_sale_token_mint_index";

DROP INDEX IF EXISTS "public"."token_sale_user_wallet_index";

DROP TABLE "public"."token_sale";

DROP INDEX IF EXISTS "public"."token_purchase_token_mint_index";

CREATE  INDEX "token_purchase_created_at_index" on
  "public"."token_purchase" using btree ("created_at");

DROP INDEX IF EXISTS "public"."token_purchase_user_wallet_index";

DROP INDEX IF EXISTS "public"."token_purchase_created_at_index";

DROP TABLE "public"."token_purchase";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table IF EXISTS public.token_transaction CASCADE;
-- DROP table IF EXISTS public.wallet_transaction CASCADE;

CREATE OR REPLACE FUNCTION public.sell_token(user_wallet character varying, token_address text, amount_to_sell numeric, token_price double precision)
 RETURNS token_transaction
 LANGUAGE plpgsql
AS $function$
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
