import { graphql } from "./init";

export const GetLatestTokensSubscription = graphql(`
  subscription GetLatestTokens($limit: Int = 10) {
    token(order_by: {updated_at: desc}, limit: $limit) {
      id
      symbol
      supply
      updated_at
    }
  }
`);