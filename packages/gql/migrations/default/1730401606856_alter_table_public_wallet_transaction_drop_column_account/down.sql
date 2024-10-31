alter table "public"."wallet_transaction" alter column "account" drop not null;
alter table "public"."wallet_transaction" add column "account" uuid;
