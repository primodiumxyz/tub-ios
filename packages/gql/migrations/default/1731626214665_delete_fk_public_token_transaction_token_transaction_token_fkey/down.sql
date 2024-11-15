alter table "public"."token_transaction"
  add constraint "token_transaction_token_fkey"
  foreign key ("token")
  references "public"."token"
  ("id") on update no action on delete cascade;
