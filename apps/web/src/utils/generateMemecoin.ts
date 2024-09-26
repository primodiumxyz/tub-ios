export type CoinData = {
  id: string;
  name: string;
  symbol: string;
};


export const solToLamports = (sol: number) => {
  return BigInt(sol * 1_000_000_000);
};

export const lamportsToSol = (lamports: bigint) => {
  const raw = Number(lamports) / 1_000_000_000;
  if (raw < 0.001) {
    return raw
  }
  return raw.toFixed(2);
};
