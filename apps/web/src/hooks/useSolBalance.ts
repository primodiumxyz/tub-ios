import { queries } from "@tub/gql";
import { useQuery } from "urql";
import { useEffect, useMemo, useState } from "react";

// export const useSolBalance = ({ publicKey }: { publicKey: PublicKey }) => {
//   const { connection } = useConnection();
//   const [balance, setBalance] = useState(0);
//   const [loading, setLoading] = useState(true);

//   useEffect(() => {
//     const fetchBalance = async () => {
//       if (publicKey) {
//         try {
//           const balance = await connection.getBalance(publicKey);
//           setBalance(balance / LAMPORTS_PER_SOL);
//           setLoading(false);
//         } catch (error) {
//           console.error("Error fetching balance:", error);
//         }
//       }
//     };

//     fetchBalance();

//     const interval = setInterval(fetchBalance, 1000);
//     return () => clearInterval(interval);
//   }, [connection, publicKey]);

//   return { balance, loading };
// };

export const useSolBalance = ({ userId }: { userId: string }) => {
  const [initialBalance, setInitialBalance] = useState(0n);
  const [initialSet, setInitialSet] = useState(false);
  const [userDebit, refetchDebit] = useQuery({
    query: queries.GetAccountBalanceDebitQuery,
    variables: { accountId: userId },
  });

  const [userCredit, refetchCredit] = useQuery({
    query: queries.GetAccountBalanceCreditQuery,
    variables: { accountId: userId },
  });

  useEffect(() => {
    const interval = setInterval(() => {
      refetchDebit({
        requestPolicy: "network-only",
      });
      refetchCredit({
        requestPolicy: "network-only",
      });
    }, 10000);
    return () => clearInterval(interval);
  }, [refetchDebit, refetchCredit]);

  const loading = useMemo(
    () => userDebit.fetching || userCredit.fetching,
    [userDebit.fetching, userCredit.fetching]
  );
  const balance = useMemo(() => {
    const debit =
      userDebit.data?.account_transaction_aggregate?.aggregate?.sum?.amount;
    const credit =
      userCredit.data?.account_transaction_aggregate?.aggregate?.sum?.amount;
    const balance = BigInt(credit ?? 0) - BigInt(debit ?? 0);
    if (!initialSet && balance !== 0n ) {
      setInitialBalance(balance);
      setInitialSet(true);
    }
    return balance;
  }, [userDebit, userCredit.data, initialSet]);
  return { balance, initialBalance, loading };
};
