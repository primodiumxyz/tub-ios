CREATE TABLE "public"."trade_history" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "token_mint" text NOT NULL, "token_price_usd" numeric NOT NULL, "volume_usd" numeric NOT NULL, "token_metadata" token_metadata NOT NULL, PRIMARY KEY ("id") );COMMENT ON TABLE "public"."trade_history" IS E'History of trades on subscribed accounts from the indexer.';

CREATE TYPE token_metadata AS (
    name VARCHAR(255),
    symbol VARCHAR(10),
    description TEXT,
    image_uri TEXT,
    external_url TEXT,
    supply NUMERIC,
    is_pump_token BOOLEAN
);