import { create } from 'zustand';
import { Keypair } from '@solana/web3.js';

interface TokenStore {
  tokenAccounts: Keypair[];
  addTokenAccount: (account: Keypair) => void;
}

export const useTokenStore = create<TokenStore>((set) => ({
  tokenAccounts: [],
  addTokenAccount: (account) => set((state) => ({ tokenAccounts: [...state.tokenAccounts, account] })),
}));