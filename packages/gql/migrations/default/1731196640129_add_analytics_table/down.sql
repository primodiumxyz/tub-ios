
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."analytics_client_event" add column "build" text
--  null;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."analytics_client_event" add column "created_at" timestamptz
--  not null default now();

alter table "public"."analytics_client_event" alter column "environment" set default ''development'::text';
alter table "public"."analytics_client_event" alter column "environment" drop not null;
alter table "public"."analytics_client_event" add column "environment" text;


-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."analytics_client_event" add column "error_details" text
--  null;

alter table "public"."analytics_client_event" rename column "user_agent" to "client";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."analytics_client_event" add column "source" text
--  null;

alter table "public"."analytics_client_event" rename to "analytics_client_events";

DROP TABLE "public"."analytics_client_events";
