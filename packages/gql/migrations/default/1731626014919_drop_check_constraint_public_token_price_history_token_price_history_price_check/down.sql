alter table "public"."token_price_history" add constraint "token_price_history_price_check" check (CHECK (price >= 0::numeric));
