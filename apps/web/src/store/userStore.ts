import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface UserStore {
  username: string;
  userId: string;
  jwtToken: string;
  setUsername: (username: string) => void;
  setUserId: (userId: string) => void;
  resetUser: () => void;
  setJwtToken: (jwtToken: string) => void;
}

export const useUserStore = create(
  persist<UserStore>(
    (set) => ({
      username: '',
      userId: '',
      jwtToken: '',
      setUsername: (username) => set({ username }),
      setUserId: (userId) => set({ userId }),
      setJwtToken: (jwtToken) => set({ jwtToken }),
      resetUser: () => set({ username: '', userId: '', jwtToken: '' }),
    }),
    {
      name: 'user-storage', // name of the item in localStorage
      storage: createJSONStorage(() => localStorage),
    }
  )
);

// ... rest of the file ...