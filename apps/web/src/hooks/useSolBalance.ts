import { PublicKey } from "@solana/web3.js";
import { useTokenBalance } from "./useTokenBalance";

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

export const SOL_ID = "e9e2d8a1-0b57-4b9b-9949-a790de9b24ae"

export const useSolBalance = ({ publicKey }: { publicKey: PublicKey }) => {
  return useTokenBalance({ publicKey, tokenId: SOL_ID });
}