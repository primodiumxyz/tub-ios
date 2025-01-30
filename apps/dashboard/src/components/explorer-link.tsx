import { FC } from "react";
import { ExternalLink } from "lucide-react";

type ExplorerLinkProps = {
  address: string;
  url: string;
};

/**
 * Component to display a link to an explorer (Solscan, Photon, etc.) for a given address
 *
 * @param props - The props {@link ExplorerLinkProps}
 * @returns The explorer link {@link ExplorerLink}
 */
export const ExplorerLink: FC<ExplorerLinkProps> = ({ address, url }) => {
  return (
    <a href={url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1">
      {address.slice(0, 4)}...{address.slice(-4)}
      <ExternalLink className="w-4 h-4" />
    </a>
  );
};
