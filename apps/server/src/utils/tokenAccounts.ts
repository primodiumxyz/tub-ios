import { PublicKey } from "@solana/web3.js";
import { getAssociatedTokenAddressSync } from "@solana/spl-token";

/**
 * Derives associated token accounts for buy and sell tokens
 * @param userPublicKey - The user's public key
 * @param buyTokenId - ID of token to buy
 * @param sellTokenId - ID of token to sell
 * @returns Object containing derived token account addresses
 */
export function deriveTokenAccounts(
  userPublicKey: PublicKey,
  buyTokenId: string,
  sellTokenId: string,
): { buyTokenAccount: PublicKey; sellTokenAccount: PublicKey } {
  const buyTokenAccount = getAssociatedTokenAddressSync(new PublicKey(buyTokenId), userPublicKey, false);
  const sellTokenAccount = getAssociatedTokenAddressSync(new PublicKey(sellTokenId), userPublicKey, false);
  return { buyTokenAccount, sellTokenAccount };
}
