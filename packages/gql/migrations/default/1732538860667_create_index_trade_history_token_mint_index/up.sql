CREATE  INDEX "trade_history_token_mint_index" on
  "public"."trade_history" using btree ("token_mint");
