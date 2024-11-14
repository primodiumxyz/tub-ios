import { Token } from "@/lib/types";

export const TokenChart = ({ token }: { token: Token }) => {
  return <div>{token.name}</div>;
};
