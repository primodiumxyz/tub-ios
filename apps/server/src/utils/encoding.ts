import bs58 from "bs58";

/**
 * Converts a base64 string to base58 encoding
 * @param base64String - The base64-encoded string to convert
 * @returns The base58-encoded string
 * @throws Error if input is invalid base64
 *
 * @example
 * const base58String = base64ToBase58('SGVsbG8gV29ybGQ=');
 * // Returns: '2NEpo7TZRRrLZSi2U'
 */
export function base64ToBase58(base64String: string): string {
  try {
    // First convert base64 to Buffer
    const buffer = Buffer.from(base64String, "base64");
    // Then convert Buffer to base58
    return bs58.encode(buffer);
  } catch (error) {
    throw new Error(`Failed to convert base64 to base58: ${error}`);
  }
}

/**
 * Converts a base58 string to base64 encoding
 * @param base58String - The base58-encoded string to convert
 * @returns The base64-encoded string
 * @throws Error if input is invalid base58
 *
 * @example
 * const base64String = base58ToBase64('2NEpo7TZRRrLZSi2U');
 * // Returns: 'SGVsbG8gV29ybGQ='
 */
export function base58ToBase64(base58String: string): string {
  try {
    // First decode base58 to Buffer
    const buffer = Buffer.from(bs58.decode(base58String));
    // Then convert Buffer to base64 string
    return buffer.toString("base64");
  } catch (error) {
    throw new Error(`Failed to convert base58 to base64: ${error}`);
  }
}
