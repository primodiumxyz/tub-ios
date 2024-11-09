alter table "public"."analytics_client_event" add column "created_at" timestamptz
 not null default now();
