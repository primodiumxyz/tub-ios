
-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."tab_selected";

-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."tab_dwell_time";


-- Could not auto-generate a down migration.
-- Please write an appropriate down migration for the SQL below:
-- DROP table "public"."analytics_client_event";

DROP TABLE "public"."token_dwell_time";

DROP TABLE "public"."tab_dwell_time";

DROP TABLE "public"."app_dwell_time";

alter table "public"."token_sale" drop constraint "token_sale_id_key";

alter table "public"."token_purchase" drop constraint "token_purchase_id_key";

alter table "public"."tab_selected" drop constraint "tab_selected_id_key";

alter table "public"."loading_time" drop constraint "loading_time_id_key";

DROP TABLE "public"."loading_time";

DROP TABLE "public"."tab_selected";
