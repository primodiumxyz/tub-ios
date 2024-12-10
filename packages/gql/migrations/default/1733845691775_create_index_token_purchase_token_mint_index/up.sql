CREATE  INDEX "token_purchase_token_mint_index" on
  "public"."token_purchase" using btree ("token_mint");
