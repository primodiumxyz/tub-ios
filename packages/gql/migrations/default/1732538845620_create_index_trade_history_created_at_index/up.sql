CREATE  INDEX "trade_history_created_at_index" on
  "public"."trade_history" using btree ("created_at");
