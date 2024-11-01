-- rename account_transaction to wallet_transaction
alter table "public"."account_transaction" rename TO "wallet_transaction";

alter table "public"."token_transaction" rename column "account_transaction" to "wallet_transaction";
