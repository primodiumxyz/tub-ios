import { graphql } from "./init";

export const RegisterNewUserMutation = graphql(`
  mutation RegisterNewUser($username: String!, $amount: numeric!) {
    insert_account_one(
      object: { account_transactions: { data: { amount: $amount, transaction_type: "credit" } }, username: $username }
    ) {
      id
    }
  }
`);
