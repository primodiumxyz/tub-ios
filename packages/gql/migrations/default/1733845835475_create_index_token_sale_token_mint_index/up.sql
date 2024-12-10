CREATE  INDEX "token_sale_token_mint_index" on
  "public"."token_sale" using btree ("token_mint");
