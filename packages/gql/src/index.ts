import { client } from "./lib/init";
import * as mutations from "./lib/mutations";
import * as queries from "./lib/queries";

const db = {
  getAllAccounts: () => client.query(queries.GetAllAccountsQuery, {}).toPromise(),
  getAllTokens: () => client.query(queries.GetAllTokensQuery, {}).toPromise(),
  registerNewUser: (username: string, airdropAmount: bigint) =>
    client
      .mutation(mutations.RegisterNewUserMutation, {
        username,
        amount: airdropAmount.toString(),
      })
      .toPromise(),
  getAccountTokenBalance: async (accountId: string, tokenId: string) => {
    const credit = await client
      .query(queries.GetAccountTokenCreditQuery, {
        accountId,
        tokenId,
      })
      .toPromise();

      const creditValue = (credit.data?.token_transaction_aggregate.aggregate?.sum?.amount as bigint || null) ?? 0n;

    const debit = await client
      .query(queries.GetAccountTokenDebitQuery, {
        accountId,
        tokenId,
      })
      .toPromise();

      const debitValue = (debit.data?.token_transaction_aggregate.aggregate?.sum?.amount as bigint || null) ?? 0n;

    return creditValue - debitValue;
  },
};

export { client, db };
