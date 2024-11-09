alter table "public"."analytics_client_event" alter column "environment" set default ''development'::text';
alter table "public"."analytics_client_event" alter column "environment" drop not null;
alter table "public"."analytics_client_event" add column "environment" text;
