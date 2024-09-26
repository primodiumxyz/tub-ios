import { lamportsToSol } from "../utils/generateMemecoin";

export const Price = ({
  lamports,
  className,
}: {
  lamports: bigint;
  className?: string;
}) => {
  return <span className={className}>{lamportsToSol(lamports)}</span>;
};
  