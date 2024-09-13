import { useMemo, useState } from "react";
import { useCore } from "../hooks/useCore";
import { useConnection, useWallet } from "@solana/wallet-adapter-react";
import { PublicKey, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { BN } from "@coral-xyz/anchor";
import { Balance } from "./Balance";
import { useBalance } from "../hooks/useBalance";

export default function TransferSolForm({publicKey}: {publicKey: PublicKey}) {
  const { programs } = useCore();
  const { connection } = useConnection();
  const { sendTransaction } = useWallet();
  const [isLoading, setIsLoading] = useState(false);
  const [recipient, setRecipient] = useState("");
  const [amount, setAmount] = useState(0.1);

  const balance = useBalance({ publicKey });
  const isValid = useMemo(() => {
  try {
    new PublicKey(recipient);
    return true;
  } catch (error) {
    return false;
  }
  }, [recipient]);

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseFloat(e.target.value);
    if(isNaN(value)) {
      setAmount(0);
    } else if (value > balance.balance) {
      setAmount(balance.balance);
    } else if(value < 0) {
      setAmount(0);
    } else {
      setAmount(value);
    }
  };
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!publicKey) {
      console.error("No public key found");
      return;
    }

    setIsLoading(true);

    try {
      const recipientPublicKey = new PublicKey(recipient);
      const lamports = amount * LAMPORTS_PER_SOL;

      console.log("Creating transaction...");
      const transaction = await programs.transferSol.methods
        .transferSolWithCpi(new BN(lamports))
        .accounts({
          payer: publicKey,
          recipient: recipientPublicKey,
        })
        .transaction();

      transaction.feePayer = publicKey;

      console.log("Sending transaction...");

      const transactionSignature = await sendTransaction(transaction, connection);

      console.log("Transaction sent successfully");
      console.log(
        `View on explorer: https://solana.fm/tx/${transactionSignature}?cluster=devnet-alpha`
      );
    } catch (error) {
      console.error("Error transferring SOL:", error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center bg-slate-300 rounded-xl p-2">
      <h2 className="text-sm font-bold text-center ">Transfer SOL</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="recipient" className="block text-sm font-medium text-gray-700 mb-2">
            Recipient Public Key
          </label>
          <div className="relative">
            <input
              type="text"
              id="recipient"
              value={recipient}
              onChange={(e) => setRecipient(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              required
            />
            {isValid && (
              <div className="text-xs text-gray-500 inline">
                Balance: <Balance publicKey={new PublicKey(recipient)} inline />
              </div>
            )}
          </div>
        </div>
        <div>
          <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-1">
            Amount (SOL)
          </label>
          <input
            type="number"
            id="amount"
            value={amount}
            onChange={handleAmountChange}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
            step="0.000000001"
            min="0"
            required
          />
        </div>
        <button
          type="submit"
          disabled={!publicKey || isLoading}
          className="btn-primary w-full"
        >
          {isLoading ? (
            <>
              <span className="inline-block animate-spin mr-2">&#9696;</span>
              Transferring SOL...
            </>
          ) : (
            "Transfer SOL"
          )}
        </button>
      </form>
    </div>
  );
}
