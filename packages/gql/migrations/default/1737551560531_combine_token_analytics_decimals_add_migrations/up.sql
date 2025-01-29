
alter table "public"."token_purchase" add column "token_decimals" numeric
 null default '6';

ALTER TABLE "public"."token_purchase" ALTER COLUMN "token_decimals" TYPE int4;
alter table "public"."token_purchase" alter column "token_decimals" set default '6';

alter table "public"."token_sale" add column "token_decimals" integer
 null default '6';
