import { ReactNode, useMemo } from "react";
import { Provider as UrqlProvider } from "urql";
import { createClient } from "@tub/gql";

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
    <UrqlProvider value={client}>{children}</UrqlProvider>
  );
};
