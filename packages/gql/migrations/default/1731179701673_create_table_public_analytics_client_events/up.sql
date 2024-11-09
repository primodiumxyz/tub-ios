CREATE TABLE "public"."analytics_client_events" ("id" uuid NOT NULL DEFAULT gen_random_uuid(), "user" text NOT NULL, "client" text NOT NULL DEFAULT 'ios', "name" text NOT NULL, "metadata" jsonb, "environment" text NOT NULL DEFAULT 'development', PRIMARY KEY ("id") , UNIQUE ("id"));
CREATE EXTENSION IF NOT EXISTS pgcrypto;
