import { beforeAll, describe, expect, it } from "vitest";
import { createClient, GqlClient } from "../src/index"


describe("query tests", () => {
  let gql: GqlClient;

  beforeAll(async () => {
    gql = await createClient({ url: "http://localhost:8080/v1/graphql", hasuraAdminSecret: "password" });
  });

  it("should be able to get all accounts", async () => {
    const result = await gql.db.GetAllAccountsQuery();

    expect(result.data?.account).toBeInstanceOf(Array);
    expect(result.data?.account.length).toBeGreaterThan(0);
  });
});
