CREATE  INDEX "token_purchase_user_wallet_index" on
  "public"."token_purchase" using btree ("user_wallet");
