import { create } from 'zustand';


interface UserStore {
  username: string;
  userId: string;
  setUsername: (username: string) => void;
  setUserId: (userId: string) => void;
  resetUser: () => void;
}

export const useUserStore = create<UserStore>((set) => ({
  username: '',
  userId: '',
  setUsername: (username) => set({ username }),
  setUserId: (userId) => set({ userId }),
  resetUser: () => set({ username: '', userId: '' }),
}));
