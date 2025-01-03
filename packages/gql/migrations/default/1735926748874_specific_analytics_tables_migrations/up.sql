

CREATE TABLE "public"."tab_selected" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text, "error_details" text, "build" text, "tab_name" text NOT NULL, PRIMARY KEY ("id") );
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE "public"."loading_time" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text, "error_details" text, "build" text, "identifier" text NOT NULL, "time_elapsed_ms" numeric NOT NULL, "attempt_number" integer NOT NULL, "total_time_ms" numeric NOT NULL, "average_time_ms" numeric NOT NULL, PRIMARY KEY ("id") );
CREATE EXTENSION IF NOT EXISTS pgcrypto;

alter table "public"."loading_time" add constraint "loading_time_id_key" unique ("id");

alter table "public"."tab_selected" add constraint "tab_selected_id_key" unique ("id");

alter table "public"."token_purchase" add constraint "token_purchase_id_key" unique ("id");

alter table "public"."token_sale" add constraint "token_sale_id_key" unique ("id");

CREATE TABLE "public"."app_dwell_time" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text, "error_details" text, "build" text, "dwell_time_ms" numeric NOT NULL, PRIMARY KEY ("id") , UNIQUE ("id"));
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE "public"."tab_dwell_time" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text, "error_details" text, "build" text, "tab_name" text NOT NULL, "dwell_time_ms" numeric NOT NULL, PRIMARY KEY ("id") , UNIQUE ("id"));
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE "public"."token_dwell_time" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "created_at" timestamptz NOT NULL DEFAULT now(), "user_wallet" text NOT NULL, "user_agent" text NOT NULL, "source" text, "error_details" text, "build" text, "token_mint" text NOT NULL, "dwell_time_ms" numeric NOT NULL, PRIMARY KEY ("id") , UNIQUE ("id"));
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP table "public"."analytics_client_event";

DROP table "public"."tab_dwell_time";

DROP table "public"."tab_selected";
