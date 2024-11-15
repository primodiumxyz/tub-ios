alter table "public"."token_transaction" drop constraint "token_transaction_token_fkey";
alter table public.token_transaction alter column token type text;
