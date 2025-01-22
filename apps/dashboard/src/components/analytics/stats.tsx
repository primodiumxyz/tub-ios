import { useState } from "react";

import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useStats } from "@/hooks/use-stats";
import { formatUsd } from "@/lib/utils";

import { ExplorerLink } from "../explorer-link";

export const Stats = () => {
  const [walletFilter, setWalletFilter] = useState<string>("");
  const [tokenFilter, setTokenFilter] = useState<string>("");
  const { stats, fetching, error } = useStats({ userWallet: walletFilter, tokenMint: tokenFilter });

  return (
    <div className="flex flex-col gap-2 w-full">
      <div className="flex items-center justify-end gap-2">
        <Input
          placeholder="Search user wallet..."
          value={walletFilter}
          onChange={(e) => setWalletFilter(e.target.value)}
          className="self-end w-[400px]"
        />
        <Input
          placeholder="Search token mint..."
          value={tokenFilter}
          onChange={(e) => setTokenFilter(e.target.value)}
          className="self-end w-[400px]"
        />
      </div>
      {fetching && <p>Loading...</p>}
      {!!error && <p>Error: {error}</p>}
      {!!stats && (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>PnL</TableHead>
              <TableHead>Volume</TableHead>
              <TableHead>Trade Count</TableHead>
              <TableHead>Success Rate</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow className="text-left">
              <TableCell>{formatUsd(stats.pnlUsd)}</TableCell>
              <TableCell>{formatUsd(stats.volumeUsd)}</TableCell>
              <TableCell>{stats.tradeCount}</TableCell>
              <TableCell>{stats.successRate}%</TableCell>
            </TableRow>
          </TableBody>
        </Table>
      )}
      <span className="text-sm text-muted-foreground flex gap-1 mx-auto">
        Showing stats for{" "}
        {walletFilter ? (
          <>
            user <ExplorerLink address={walletFilter} url={`https://solscan.io/account/${walletFilter}`} />
          </>
        ) : (
          "all wallets"
        )}{" "}
        and{" "}
        {tokenFilter ? (
          <>
            token <ExplorerLink address={tokenFilter} url={`https://photon-sol.tinyastro.io/en/lp/${tokenFilter}`} />
          </>
        ) : (
          "all tokens"
        )}
        .
      </span>
    </div>
  );
};
