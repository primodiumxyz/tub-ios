import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface UserStore {
  username: string;
  userId: string;
  setUsername: (username: string) => void;
  setUserId: (userId: string) => void;
  resetUser: () => void;
}

export const useUserStore = create(
  persist<UserStore>(
    (set) => ({
      username: '',
      userId: '',
      setUsername: (username) => set({ username }),
      setUserId: (userId) => set({ userId }),
      resetUser: () => set({ username: '', userId: '' }),
    }),
    {
      name: 'user-storage', // name of the item in localStorage
      storage: createJSONStorage(() => localStorage),
    }
  )
);

// ... rest of the file ...