
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."token_sale" add column "token_decimals" integer
--  null default '6';

alter table "public"."token_purchase" alter column "token_decimals" set default '6'::numeric;
ALTER TABLE "public"."token_purchase" ALTER COLUMN "token_decimals" TYPE numeric;

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- alter table "public"."token_purchase" add column "token_decimals" numeric
--  null default '6';
