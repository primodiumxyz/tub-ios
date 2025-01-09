import { Keypair } from "@solana/web3.js";

export function createWallet() {
  const wallet = Keypair.generate();
  return wallet.publicKey.toString();
}

export const toPgComposite = (obj: Record<string, unknown>): string => {
  const values = Object.values(obj).map((val) => {
    if (val === null || val === undefined) return null;

    if (typeof val === "string") {
      // Escape special characters and quotes
      const escaped = val
        // Replace backslashes first to avoid double-escaping
        .replace(/\\/g, "\\\\")
        // Escape quotes
        .replace(/"/g, '\\"')
        // Replace newlines
        .replace(/\n/g, "\\n")
        // Replace carriage returns
        .replace(/\r/g, "\\r")
        // Replace tabs
        .replace(/\t/g, "\\t");

      return `"${escaped}"`;
    }

    if (typeof val === "number") {
      return isNaN(val) ? null : val.toString();
    }

    if (typeof val === "boolean") {
      return val.toString();
    }

    // For any other value, convert to string and escape
    const stringVal = val.toString();
    return `"${stringVal.replace(/"/g, '\\"')}"`;
  });

  return `(${values.join(",")})`;
};
