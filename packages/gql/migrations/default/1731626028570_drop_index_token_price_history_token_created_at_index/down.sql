CREATE  INDEX "token_price_history_token_created_at_index" on
  "public"."token_price_history" using btree ("created_at", "internal_token_transaction_ref", "token");
