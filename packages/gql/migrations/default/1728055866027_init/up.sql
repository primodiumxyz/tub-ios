SET check_function_bodies = false;
CREATE TYPE public.transaction_type AS ENUM (
    'credit',
    'debit'
);
CREATE TABLE public.token_transaction (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token uuid NOT NULL,
    amount numeric(78,0) NOT NULL,
    account_transaction uuid NOT NULL,
    transaction_type public.transaction_type NOT NULL
);
CREATE FUNCTION public.buy_token(account_id uuid, token_id uuid, amount_to_buy numeric, token_cost numeric DEFAULT NULL::numeric) RETURNS public.token_transaction
    LANGUAGE plpgsql
    AS $$
DECLARE
    latest_price NUMERIC(78,0);
    total_cost NUMERIC(78,0);
    credits NUMERIC(78,0);
    debits NUMERIC(78,0);
    account_balance NUMERIC(78,0);
    balance_multiplier NUMERIC := 1;  -- Adjust as needed
    account_transaction_id UUID;
    token_txn token_transaction%ROWTYPE;
BEGIN
    -- Lock the account to prevent concurrent transactions
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
    -- Calculate total cost -- convert to lamports/gwei
    total_cost := latest_price/CAST(1e9 as NUMERIC) * amount_to_buy;
    -- Get account credits
    SELECT COALESCE(SUM(amount), 0) INTO credits
    FROM account_transaction
    WHERE account = account_id AND transaction_type = 'credit';
    -- Get account debits
    SELECT COALESCE(SUM(amount), 0) INTO debits
    FROM account_transaction
    WHERE account = account_id AND transaction_type = 'debit';
    -- Calculate account balance
    account_balance := credits - debits;
    -- Adjust account balance with the conversion rate to go from native to usd, solana, etc.
    account_balance := account_balance * balance_multiplier;
    -- Check if account has enough balance
    IF account_balance < total_cost THEN
        RAISE EXCEPTION 'Insufficient balance. Required: %, Available: %', total_cost, account_balance;
    END IF;
    -- Insert a new account_transaction for the cost (debit)
    INSERT INTO account_transaction (account, amount, transaction_type)
    VALUES (account_id, total_cost, 'debit')
    RETURNING id INTO account_transaction_id;
    -- Insert a new token_transaction for the tokens (credit)
    INSERT INTO token_transaction (token, amount, account_transaction, transaction_type)
    VALUES (token_id, amount_to_buy, account_transaction_id, 'credit')
    RETURNING * INTO token_txn;
    -- Insert a new record into token_price_history
    INSERT INTO token_price_history (token, price)
    VALUES (token_id, latest_price);
    -- Return the token_transaction record
    RETURN token_txn;
END;
$$;
CREATE FUNCTION public.sell_token(account_id uuid, token_id uuid, amount_to_sell numeric, token_cost numeric DEFAULT NULL::numeric) RETURNS public.token_transaction
    LANGUAGE plpgsql
    AS $$
DECLARE
    latest_price NUMERIC(78,0);
    total_proceeds NUMERIC(78,0);
    balance_multiplier NUMERIC := 1;  -- Adjust as needed
    credits NUMERIC(78,0);
    debits NUMERIC(78,0);
    account_balance NUMERIC(78,0);
    token_credits NUMERIC(78,0);
    token_debits NUMERIC(78,0);
    token_balance NUMERIC(78,0);
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
    total_proceeds := total_proceeds * balance_multiplier;
    -- Get token credits (tokens acquired)
    SELECT COALESCE(SUM(amount), 0) INTO token_credits
    FROM token_transaction
    WHERE account_transaction IN (
        SELECT id FROM account_transaction WHERE account = account_id
    ) AND transaction_type = 'credit' AND token = token_id;
    -- Get token debits (tokens sold)
    SELECT COALESCE(SUM(amount), 0) INTO token_debits
    FROM token_transaction
    WHERE account_transaction IN (
        SELECT id FROM account_transaction WHERE account = account_id
    ) AND transaction_type = 'debit' AND token = token_id;
    -- Calculate token balance
    token_balance := token_credits - token_debits;
    -- Check if account has enough tokens to sell
    IF token_balance < amount_to_sell THEN
        RAISE EXCEPTION 'Insufficient token balance. Available: %, Requested: %', token_balance, amount_to_sell;
    END IF;
    -- Insert a new account_transaction for the proceeds (credit)
    INSERT INTO account_transaction (account, amount, transaction_type)
    VALUES (account_id, total_proceeds, 'credit')
    RETURNING id INTO account_transaction_id;
    -- Insert a new token_transaction for the tokens sold (debit)
    INSERT INTO token_transaction (token, amount, account_transaction, transaction_type)
    VALUES (token_id, amount_to_sell, account_transaction_id, 'debit')
    RETURNING * INTO token_txn;
    -- Insert a new record into token_price_history
    INSERT INTO token_price_history (token, price)
    VALUES (token_id, latest_price);
    -- Return the token_transaction record
    RETURN token_txn;
END;
$$;
CREATE TABLE public.account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(16) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TABLE public.account_transaction (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account uuid NOT NULL,
    amount numeric(78,0) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    transaction_type public.transaction_type NOT NULL,
    CONSTRAINT amount_contraint CHECK (((amount)::numeric >= (0)::numeric))
);
CREATE TABLE public.token (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    symbol character varying(10) NOT NULL,
    uri text,
    supply numeric(78,0) NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mint text
);
COMMENT ON COLUMN public.token.mint IS 'token mint address (only for real tokens)';
CREATE TABLE public.token_price_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token uuid NOT NULL,
    price numeric(78,0) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT token_price_history_price_check CHECK ((price >= (0)::numeric))
);
ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.account_transaction
    ADD CONSTRAINT account_transaction_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.token
    ADD CONSTRAINT token_mint_key UNIQUE (mint);
ALTER TABLE ONLY public.token
    ADD CONSTRAINT token_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.token_price_history
    ADD CONSTRAINT token_price_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.token_transaction
    ADD CONSTRAINT token_transaction_pkey PRIMARY KEY (id);
CREATE INDEX token_price_histroy_created_at_index ON public.token_price_history USING btree (created_at);
ALTER TABLE ONLY public.token_transaction
    ADD CONSTRAINT fk_account_transaction FOREIGN KEY (account_transaction) REFERENCES public.account_transaction(id);
ALTER TABLE ONLY public.token_price_history
    ADD CONSTRAINT fk_token FOREIGN KEY (token) REFERENCES public.token(id);
ALTER TABLE ONLY public.token_transaction
    ADD CONSTRAINT fk_token FOREIGN KEY (token) REFERENCES public.token(id);
ALTER TABLE ONLY public.account_transaction
    ADD CONSTRAINT fk_user FOREIGN KEY (account) REFERENCES public.account(id);
