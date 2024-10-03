// Copied from @shyft.to/solana-transaction-parser-public

import { getU8Codec } from "@solana/codecs";
import { getArrayCodec, getStructCodec } from "@solana/codecs-data-structures";

export const getAccountDataSizeLayout = getStructCodec([
  ["instruction", getU8Codec()],
  ["extensions", getArrayCodec(getU8Codec(), { size: 1 })],
]);
