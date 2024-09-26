import { useQuery } from "urql";
import { useEffect, useMemo } from "react";
import { queries } from "@tub/gql";

export const useTokenBalance = ({
  userId,
  tokenId,
}: {
  userId: string;
  tokenId: string;
}) => {
  const [userDebit, refetchDebit] = useQuery({
    query: queries.GetAccountTokenDebitQuery,
    variables: { tokenId, accountId: userId },
  });
  const [userCredit, refetchCredit] = useQuery({
    query: queries.GetAccountTokenCreditQuery,
    variables: { tokenId, accountId: userId },
  });

  useEffect(() => {
    refetchDebit();
    refetchCredit();

    const interval = setInterval(() => {
      refetchDebit();
      refetchCredit();
    }, 1000);
    return () => clearInterval(interval);
  }, [refetchDebit, refetchCredit]);

  const loading = useMemo(
    () => userDebit.fetching || userCredit.fetching,
    [userDebit.fetching, userCredit.fetching]
  );
  const balance = useMemo(() => {
    const debit =
      userDebit.data?.token_transaction_aggregate?.aggregate?.sum?.amount;
    const credit =
      userCredit.data?.token_transaction_aggregate?.aggregate?.sum?.amount;
    console.log({ debit, credit });
    return Number(credit) - Number(debit);
  }, [userDebit.data, userCredit.data]);
  return { balance, loading };
};
