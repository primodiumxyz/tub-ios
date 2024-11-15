CREATE  INDEX "token_price_histroy_created_at_index" on
  "public"."token_price_history" using btree ("created_at");
