
DROP FUNCTION "public"."buy_token"("pg_catalog"."varchar", "pg_catalog"."text", "pg_catalog"."numeric", "pg_catalog"."float8");

DROP FUNCTION "public"."sell_token"("pg_catalog"."varchar", "pg_catalog"."text", "pg_catalog"."numeric", "pg_catalog"."float8");

DROP table IF EXISTS public.token_transaction CASCADE;
DROP table IF EXISTS public.wallet_transaction CASCADE;

CREATE TABLE "public"."token_purchase" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text NOT NULL, "error_details" text, "build" text NOT NULL, "token_mint" text NOT NULL, "token_price_usd" numeric NOT NULL, "token_amount" numeric NOT NULL, PRIMARY KEY ("id") );
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE  INDEX "token_purchase_created_at_index" on
  "public"."token_purchase" using btree ("created_at");

CREATE  INDEX "token_purchase_user_wallet_index" on
  "public"."token_purchase" using btree ("user_wallet");

DROP INDEX IF EXISTS "public"."token_purchase_created_at_index";

CREATE  INDEX "token_purchase_token_mint_index" on
  "public"."token_purchase" using btree ("token_mint");

CREATE TABLE "public"."token_sale" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text NOT NULL, "error_details" text, "build" text NOT NULL, "token_mint" text NOT NULL, "token_price_usd" numeric NOT NULL, "token_amount" numeric NOT NULL, PRIMARY KEY ("id") );
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE  INDEX "token_sale_user_wallet_index" on
  "public"."token_sale" using btree ("user_wallet");

CREATE  INDEX "token_sale_token_mint_index" on
  "public"."token_sale" using btree ("token_mint");

alter table "public"."token_purchase" alter column "source" drop not null;

alter table "public"."token_purchase" alter column "build" drop not null;

alter table "public"."token_sale" alter column "build" drop not null;

alter table "public"."token_sale" alter column "source" drop not null;
