alter table "public"."account_transaction"
  add constraint "account_transaction_account_fkey"
  foreign key ("account")
  references "public"."account"
  ("id") on update no action on delete cascade;
