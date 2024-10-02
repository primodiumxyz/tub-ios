import { PublicKey } from "@solana/web3.js";

type FormattableValue =
  | PublicKey
  | string
  | bigint
  | Buffer
  | { [key: string]: FormattableValue }
  | FormattableValue[]
  | unknown;
export type FormattedValue<T extends FormattableValue> = T extends PublicKey
  ? string
  : T extends bigint
    ? number
    : T extends Buffer
      ? string
      : T extends Array<infer U extends FormattableValue>
        ? Array<FormattedValue<U>>
        : T extends { [key: string]: FormattableValue }
          ? { [K in keyof T]: FormattedValue<T[K]> }
          : T;

export function bnLayoutFormatter<T extends FormattableValue>(obj: T): FormattedValue<T> {
  if (obj instanceof PublicKey) {
    return obj.toBase58() as FormattedValue<T>;
  } else if (typeof obj === "bigint" || (obj as any).constructor.name === "BN") {
    return Number(obj) as FormattedValue<T>;
  } else if (obj instanceof Buffer) {
    return obj.toString("base64") as FormattedValue<T>;
  } else if (Array.isArray(obj)) {
    return obj.map(bnLayoutFormatter) as FormattedValue<T>;
  } else if (typeof obj === "object" && obj !== null) {
    const result: { [key: string]: FormattedValue<any> } = {};
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        result[key] = bnLayoutFormatter(obj[key] as FormattableValue);
      }
    }
    return result as FormattedValue<T>;
  }
  return obj as FormattedValue<T>;
}
