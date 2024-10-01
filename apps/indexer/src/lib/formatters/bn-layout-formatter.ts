import { PublicKey } from "@solana/web3.js";

type FormattableValue = PublicKey | bigint | Buffer | { [key: string]: FormattableValue } | FormattableValue[];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function bnLayoutFormatter(obj: FormattableValue): any {
  if (obj instanceof PublicKey) {
    return obj.toBase58();
  } else if (typeof obj === "bigint") {
    return Number(obj.toString());
  } else if (obj instanceof Buffer) {
    return obj.toString("base64");
  } else if (Array.isArray(obj)) {
    return obj.map(bnLayoutFormatter);
  } else if (typeof obj === "object" && obj !== null) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result: { [key: string]: any } = {};
    for (const key in obj) {
      result[key] = bnLayoutFormatter(obj[key] as FormattableValue);
    }
    return result;
  }
  return obj;
}
