import { useQuery } from "urql";
import { queries } from "@tub/gql";
import { PublicKey } from "@solana/web3.js";
import { useMemo } from "react";

export const useTokenBalance = ({
  publicKey,
  tokenId,
}: {
  publicKey: PublicKey;
  tokenId: string;
}) => {
  const [userDebit] = useQuery({
    query: queries.GetAccountTokenDebitQuery,
    variables: { tokenId, accountId: publicKey.toBase58() },
  });
  const [userCredit] = useQuery({
    query: queries.GetAccountTokenCreditQuery,
    variables: { tokenId, accountId: publicKey.toBase58() },
  });

  const loading = useMemo(
    () => userDebit.fetching || userCredit.fetching,
    [userDebit.fetching, userCredit.fetching]
  );
  const balance = useMemo(() => {
    const debit =
      userDebit.data?.token_transaction_aggregate?.aggregate?.sum?.amount;
    const credit =
      userCredit.data?.token_transaction_aggregate?.aggregate?.sum?.amount;
    if (!debit || !credit) return 0;
    return Number(credit) - Number(debit);
  }, [userDebit.data, userCredit.data]);
  return { balance, loading };
};
