import { PublicKey, TransactionInstruction } from "@solana/web3.js";
import { createTransferInstruction } from "@solana/spl-token";
import { Config } from "./ConfigService";
import { SwapType } from "../types";

export type FeeSettings = {
  tradeFeeRecipient: PublicKey;
};

/**
 * Service for handling fee calculations and fee-related instructions
 */
export class FeeService {
  constructor(private settings: FeeSettings) {}

  getSettings(): FeeSettings {
    return this.settings;
  }

  /**
   * Calculate fee amount for a swap
   * @param usdcQuantity - Amount of USDC in the transaction
   * @param swapType - Type of swap: buy, sell_all, sell_partial
   * @param cfg - Config object, should be read as constant after high-level API call
   * @returns Fee amount in token's base units (USDC is 1e6)
   */
  calculateFeeAmount(usdcQuantity: number, swapType: SwapType, cfg: Config): number {
    let feeAmount = BigInt(0);
    if (swapType === SwapType.BUY) {
      if (cfg.MIN_TRADE_SIZE_USD * 1e6 > usdcQuantity) {
        throw new Error("USDC sell quantity is below minimum trade size");
      }
      feeAmount = (BigInt(cfg.BUY_FEE_BPS) * BigInt(usdcQuantity)) / 10000n;
    } else if (swapType === SwapType.SELL_ALL || swapType === SwapType.SELL_PARTIAL) {
      feeAmount = (BigInt(cfg.SELL_FEE_BPS) * BigInt(usdcQuantity)) / 10000n;
    }
    return Number(feeAmount);
  }

  /**
   * Creates a transfer instruction for the fee if needed
   * @param sourceAccount - Account to transfer from
   * @param userPublicKey - User's public key
   * @param feeAmount - Amount to transfer
   * @returns Transfer instruction or null if no fee
   */
  createFeeTransferInstruction(
    sourceAccount: PublicKey,
    userPublicKey: PublicKey,
    feeAmount: number,
  ): TransactionInstruction | null {
    if (feeAmount <= 0) {
      return null;
    }

    return createTransferInstruction(sourceAccount, this.settings.tradeFeeRecipient, userPublicKey, feeAmount);
  }
}
