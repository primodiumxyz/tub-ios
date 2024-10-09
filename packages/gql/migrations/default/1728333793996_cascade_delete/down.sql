
alter table "public"."token_transaction" drop constraint "token_transaction_account_transaction_fkey",
  add constraint "fk_account_transaction"
  foreign key ("account_transaction")
  references "public"."account_transaction"
  ("id") on update no action on delete no action;

alter table "public"."token_transaction" drop constraint "token_transaction_token_fkey",
  add constraint "fk_token"
  foreign key ("token")
  references "public"."token"
  ("id") on update no action on delete no action;

alter table "public"."account_transaction" drop constraint "account_transaction_account_fkey",
  add constraint "fk_user"
  foreign key ("account")
  references "public"."account"
  ("id") on update no action on delete no action;
