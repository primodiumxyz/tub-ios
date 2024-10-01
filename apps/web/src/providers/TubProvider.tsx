import { createContext, ReactNode, useCallback, useEffect, useState } from "react";
import { useUserStore } from "../store/tokenStore";
import { useServer } from "../hooks/useServer";

export type Tub = {
  username: string | null;
  userId: string | null;
  register: (username: string) => Promise<void>;
  isRegistering: boolean;
};

export const TubContext = createContext<Tub | null>(null);

type Props = {
  children: ReactNode;
};

/**
 * Provides the core context to its children components.
 *
 * @component
 * @param {Props} props - The component props.
 * @param {React.ReactNode} props.children - The children components.
 * @param {object} props.value - The value to be provided by the context.
 * @returns {JSX.Element} The rendered component.
 */
export const TubProvider = ({ children }: Props): JSX.Element => {
  const server = useServer();

  const userStore = useUserStore();

  const [isRegistering, setIsRegistering] = useState(false);
  const [username, setUsername] = useState("");

  useEffect(() => {
    setUsername(userStore.username);
  }, [userStore.username]);

  const register = useCallback(
    async (username: string) => {
      setIsRegistering(true);
      userStore.setUsername(username);
      try {
        const userId = (await server.registerNewUser.mutate({
          username: userStore.username,
      }))?.insert_account_one?.id;
      if (userId) {
        userStore.setUserId(userId);
      }
    } catch (error) {
      console.error("Error registering user:", error);
    } finally {
      setIsRegistering(false);
    }
  },
    [userStore, server.registerNewUser]
  );

  const tub = {
    username: username,
    userId: userStore.userId,
    register: register,
    isRegistering: isRegistering,
  };

  return <TubContext.Provider value={tub}>{children}</TubContext.Provider>;
};
