import { createContext, ReactNode, useMemo } from "react";
import { Provider as UrqlProvider } from "urql";
import { createClient } from "@tub/gql";
import { GqlClient } from "@tub/gql";

export const GqlClientContext = createContext<GqlClient | null>(null);

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
export const GqlProvider = ({ children }: Props): JSX.Element => {
  const client = useMemo(() => createClient({
    url: import.meta.env.VITE_GRAPHQL_URL,
  }), []);


  return (
    <GqlClientContext.Provider value={client}>
      <UrqlProvider value={client.client}>{children}</UrqlProvider>
    </GqlClientContext.Provider>
  );
};
