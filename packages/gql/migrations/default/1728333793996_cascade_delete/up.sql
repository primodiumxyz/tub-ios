
alter table "public"."account_transaction" drop constraint "fk_user",
  add constraint "account_transaction_account_fkey"
  foreign key ("account")
  references "public"."account"
  ("id") on update no action on delete cascade;

alter table "public"."token_transaction" drop constraint "fk_token",
  add constraint "token_transaction_token_fkey"
  foreign key ("token")
  references "public"."token"
  ("id") on update no action on delete cascade;

alter table "public"."token_transaction" drop constraint "fk_account_transaction",
  add constraint "token_transaction_account_transaction_fkey"
  foreign key ("account_transaction")
  references "public"."account_transaction"
  ("id") on update no action on delete cascade;
