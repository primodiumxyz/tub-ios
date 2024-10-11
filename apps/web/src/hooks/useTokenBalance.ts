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
    query: queries.GetAccountTokenBalanceDebitQuery,
    variables: { tokenId, accountId: userId },
  });
  const [userCredit, refetchCredit] = useQuery({
    query: queries.GetAccountTokenBalanceCreditQuery,
    variables: { tokenId, accountId: userId },
  });

  useEffect(() => {
    refetchDebit({
      requestPolicy: "network-only",
    });
    refetchCredit({
      requestPolicy: "network-only",
    });

    const interval = setInterval(() => {
      refetchDebit({
        requestPolicy: "network-only",
      });
      refetchCredit({
        requestPolicy: "network-only",
      });
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
    return BigInt(credit ?? 0) - BigInt(debit ?? 0);
  }, [userDebit, userCredit]);
  return { balance, loading };
};
