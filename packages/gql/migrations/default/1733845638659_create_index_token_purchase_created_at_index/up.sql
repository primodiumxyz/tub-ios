CREATE  INDEX "token_purchase_created_at_index" on
  "public"."token_purchase" using btree ("created_at");
