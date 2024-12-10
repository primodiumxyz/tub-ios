
CREATE TABLE "public"."trade_history" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "token_mint" text NOT NULL, "token_price_lamports" numeric NOT NULL, "volume_lamports" numeric NOT NULL, PRIMARY KEY ("id") );COMMENT ON TABLE "public"."trade_history" IS E'History of trades on subscribed accounts from the indexer.';
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE  INDEX "trade_history_created_at_index" on
  "public"."trade_history" using btree ("created_at");

CREATE  INDEX "trade_history_token_mint_index" on
  "public"."trade_history" using btree ("token_mint");

alter table "public"."trade_history" rename column "token_price_lamports" to "token_price_usd";

alter table "public"."trade_history" rename column "volume_lamports" to "volume_usd";

CREATE TYPE token_metadata AS (
    name VARCHAR(255),
    symbol VARCHAR(10),
    description TEXT,
    image_uri TEXT,
    external_url TEXT,
    supply NUMERIC,
    is_pump_token BOOLEAN
);

alter table "public"."trade_history" add column "token_metadata" token_metadata
 not null;
