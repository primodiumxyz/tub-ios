
DROP COLUMN token_metadata;
DROP TYPE token_metadata;
alter table "public"."trade_history" rename column "volume_usd" to "volume_lamports";

alter table "public"."trade_history" rename column "token_price_usd" to "token_price_lamports";

DROP INDEX IF EXISTS "public"."trade_history_token_mint_index";

DROP INDEX IF EXISTS "public"."trade_history_created_at_index";

DROP TABLE "public"."trade_history";
