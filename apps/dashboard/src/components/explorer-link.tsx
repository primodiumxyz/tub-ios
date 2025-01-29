import { FC } from "react";
import { ExternalLink } from "lucide-react";

type ExplorerLinkProps = {
  address: string;
  url: string;
};

export const ExplorerLink: FC<ExplorerLinkProps> = ({ address, url }) => {
  return (
    <a href={url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1">
      {address.slice(0, 4)}...{address.slice(-4)}
      <ExternalLink className="w-4 h-4" />
    </a>
  );
};
