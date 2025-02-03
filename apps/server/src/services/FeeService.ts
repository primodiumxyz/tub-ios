import { LAMPORTS_PER_SOL, PublicKey, TransactionInstruction } from "@solana/web3.js";
import { createTransferInstruction } from "@solana/spl-token";
import { Config } from "./ConfigService";
import { TransactionType } from "../types";
import { JupiterService } from "./JupiterService";
import { USDC_BASE_UNITS } from "../constants/tokens";

export type FeeSettings = {
  tradeFeeRecipient: PublicKey;
};

/**
 * Service for handling fee calculations and fee-related instructions
 * Manages trade fees, minimum fees, and fee transfer instructions
 */
export class FeeService {
  /**
   * Creates a new FeeService instance
   * @param settings - Fee configuration settings
   * @param jupiterService - Jupiter service instance for price calculations
   */
  constructor(
    private settings: FeeSettings,
    private jupiterService: JupiterService,
  ) {}

  /**
   * Returns the current fee settings
   * @returns Current fee configuration settings
   */
  getSettings(): FeeSettings {
    return this.settings;
  }

  /**
   * Calculate fee amount for a swap, ensuring it is not below the minimum fee amount
   * @param usdcQuantity - Amount of USDC in the transaction (in base units)
   * @param transactionType - Type of swap: buy, sell_all, sell_partial
   * @param cfg - Config object containing fee parameters
   * @returns Fee amount in USDC base units (1e6)
   * @throws Error if USDC quantity is below minimum trade size or fee exceeds swap value
   */
  calculateFeeAmount(usdcQuantity: number, transactionType: TransactionType, cfg: Config): number {
    let feeAmount = BigInt(0);
    if (transactionType === TransactionType.BUY) {
      if (cfg.MIN_TRADE_SIZE_USD * 1e6 > usdcQuantity) {
        throw new Error("USDC quantity is below minimum trade size");
      }
      feeAmount = (BigInt(cfg.BUY_FEE_BPS) * BigInt(usdcQuantity)) / 10000n;
    } else if (transactionType === TransactionType.SELL_ALL || transactionType === TransactionType.SELL_PARTIAL) {
      if (transactionType === TransactionType.SELL_PARTIAL && cfg.MIN_TRADE_SIZE_USD * 1e6 >= usdcQuantity) {
        throw new Error("Sell value below min partial sell size. Sell all instead.");
      }
      feeAmount = (BigInt(cfg.SELL_FEE_BPS) * BigInt(usdcQuantity)) / 10000n;
    }

    if (feeAmount < BigInt(cfg.MIN_FEE_CENTS) * BigInt(1e4)) {
      feeAmount = BigInt(cfg.MIN_FEE_CENTS) * BigInt(1e4);
    }

    if (feeAmount > BigInt(usdcQuantity)) {
      throw new Error("Fee is greater than the value being swapped");
    }

    return Number(feeAmount);
  }

  /**
   * Creates a transfer instruction for the fee if needed
   * @param sourceAccount - Token account to transfer from
   * @param userPublicKey - User's public key for authority
   * @param feeAmount - Amount of fee to transfer (in token base units)
   * @returns Transfer instruction or null if fee amount is 0 or negative
   */
  createFeeTransferInstruction(
    sourceAccount: PublicKey,
    userPublicKey: PublicKey,
    feeAmount: number,
  ): TransactionInstruction | null {
    if (feeAmount <= 0) {
      return null;
    }

    return createTransferInstruction(
      sourceAccount, // source ATA
      this.settings.tradeFeeRecipient, // destination ATA
      userPublicKey,
      feeAmount,
    );
  }

  /**
   * Calculate the amount of base USDC required to cover the ATA rent exemption
   * @param amountLamports - The amount of SOL to cover the ATA rent exemption
   * @returns Amount of USDC (in base units) required to cover the ATA rent exemption
   * @throws Error if SOL USD price fetch fails
   */
  async calculateRentExemptionFeeAmount(amountLamports: number): Promise<number> {
    const solUsdPrice = await this.jupiterService.getSolUsdPrice();
    if (!solUsdPrice) {
      throw new Error("Failed to fetch SOL USD price");
    }
    const usdcBaseUnitsPerLamport = (solUsdPrice * USDC_BASE_UNITS) / LAMPORTS_PER_SOL;
    const usdcBaseUnitExemptionFee = amountLamports * usdcBaseUnitsPerLamport;

    // add 1% to the fee to cover small price fluctuations
    const userUsdcBaseUnitExemptionFee = Math.ceil(usdcBaseUnitExemptionFee * 1.01);

    return userUsdcBaseUnitExemptionFee;
  }
}
