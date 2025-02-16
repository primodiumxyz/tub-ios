
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- drop function sell_token;
--
-- CREATE OR REPLACE FUNCTION public.sell_token(wallet varchar, token_id uuid, amount_to_sell numeric, token_cost numeric DEFAULT NULL::numeric)
--  RETURNS token_transaction
--  LANGUAGE plpgsql
-- AS $function$
-- DECLARE
--     latest_price NUMERIC;
--     total_proceeds NUMERIC;
--     token_balance NUMERIC;
--     wallet_transaction_id UUID;
--     token_txn token_transaction%ROWTYPE;
-- BEGIN
--     -- Acquire an advisory lock on the wallet
--     PERFORM pg_advisory_xact_lock(hashtext(wallet::text));
--     -- Determine the latest price
--     IF token_cost IS NOT NULL THEN
--         latest_price := token_cost;
--     ELSE
--         -- Get the latest price of the token
--         SELECT price INTO latest_price
--         FROM token_price_history
--         WHERE token = token_id
--         ORDER BY created_at DESC
--         LIMIT 1;
--         IF latest_price IS NULL THEN
--             RAISE EXCEPTION 'Token price not found for token_id %', token_id;
--         END IF;
--     END IF;
--     -- Calculate total proceeds
--     total_proceeds := latest_price/CAST(1e9 as numeric) * amount_to_sell;
--     -- Adjust total proceeds with the balance multiplier
--     total_proceeds := total_proceeds;
--     -- Get token balance (tokens acquired)
--     SELECT COALESCE(SUM(amount), 0) INTO token_balance
--     FROM token_transaction
--     WHERE wallet_transaction IN (
--         SELECT id FROM wallet_transaction WHERE wallet = wallet
--     ) AND token = token_id;
--     -- Check if wallet has enough tokens to sell
--     IF token_balance < amount_to_sell THEN
--         RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
--     END IF;
--     -- Insert a new wallet_transaction for the proceeds (credit)
--     INSERT INTO wallet_transaction (wallet, amount)
--     VALUES (wallet, total_proceeds)
--     RETURNING id INTO wallet_transaction_id;
--     -- Insert a new token_transaction for the tokens sold (debit)
--     INSERT INTO token_transaction (token, amount, wallet_transaction)
--     VALUES (token_id, -amount_to_sell, wallet_transaction_id)
--     RETURNING * INTO token_txn;
--     -- Insert a new record into token_price_history
--     INSERT INTO token_price_history (token, price, internal_token_transaction_ref)
--     VALUES (token_id, latest_price, token_txn.id);
--     -- Return the token_transaction record
--     RETURN token_txn;
-- END;
-- $function$;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP function buy_token;
--
-- CREATE OR REPLACE FUNCTION public.buy_token(wallet varchar, token_id uuid, amount_to_buy numeric, token_cost numeric DEFAULT NULL::numeric)
--  RETURNS token_transaction
--  LANGUAGE plpgsql
-- AS $function$
-- DECLARE
--     latest_price NUMERIC;
--     total_cost NUMERIC;
--     wallet_balance NUMERIC;
--     wallet_transaction_id UUID;
--     token_txn token_transaction%ROWTYPE;
-- BEGIN
--     -- Lock the account to prevent concurrent transactions
--     PERFORM pg_advisory_xact_lock(hashtext(wallet::text));
--     -- Determine the latest price
--     IF token_cost IS NOT NULL THEN
--         latest_price := token_cost;
--     ELSE
--         -- Get the latest price of the token
--         SELECT price INTO latest_price
--         FROM token_price_history
--         WHERE token = token_id
--         ORDER BY created_at DESC
--         LIMIT 1;
--         IF latest_price IS NULL THEN
--             RAISE EXCEPTION 'Token price not found for token_id %', token_id;
--         END IF;
--     END IF;
--     -- Calculate total cost -- convert to lamports/gwei
--     total_cost := latest_price/CAST(1e9 as NUMERIC) * amount_to_buy;
--     -- Get account balance
--     SELECT COALESCE(SUM(amount), 0) INTO wallet_balance
--     FROM wallet_transaction
--     WHERE wallet_transaction.wallet = wallet;
--     -- Check if account has enough balance
--     IF account_balance < total_cost THEN
--         RAISE EXCEPTION 'Insufficient balance. Required: %, Available: %', total_cost, account_balance;
--     END IF;
--     -- Insert a new account_transaction for the cost (debit)
--     INSERT INTO wallet_transaction (account, amount)
--     VALUES (wallet, -total_cost)
--     RETURNING id INTO wallet_transaction_id;
--     -- Insert a new token_transaction for the tokens (credit)
--     INSERT INTO token_transaction (token, amount, wallet_transaction)
--     VALUES (token_id, amount_to_buy, wallet_transaction_id)
--     RETURNING * INTO token_txn;
--     -- Insert a new record into token_price_history
--     INSERT INTO token_price_history (token, price, internal_token_transaction_ref)
--     VALUES (token_id, latest_price, token_txn.id);
--     -- Return the token_transaction record
--     RETURN token_txn;
-- END;
-- $function$;

DROP INDEX IF EXISTS "public"."wallet_index";

alter table "public"."wallet_transaction" alter column "account" drop not null;
alter table "public"."wallet_transaction" add column "account" uuid;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."wallet_transaction" add column "wallet" varchar
--  not null;

alter table "public"."token_transaction" rename column "wallet_transaction" to "account_transaction";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."account";

alter table "public"."account_transaction"
  add constraint "account_transaction_account_fkey"
  foreign key ("account")
  references "public"."account"
  ("id") on update no action on delete cascade;
