import {
  Connection,
  Keypair,
  MessageV0,
  PublicKey,
  TransactionInstruction,
  TransactionMessage,
  VersionedTransaction,
  AddressLookupTableAccount,
  TransactionConfirmationStatus,
  ComputeBudgetProgram,
  ComputeBudgetInstruction,
  RpcResponseAndContext,
  SimulatedTransactionResponse,
} from "@solana/web3.js";
import bs58 from "bs58";
import { config } from "../utils/config";
import { ATA_PROGRAM_PUBLIC_KEY, MAX_CHAIN_COMPUTE_UNITS, TOKEN_PROGRAM_PUBLIC_KEY } from "../constants/tokens";
import { Config } from "./ConfigService";
import { createCloseAccountInstruction } from "@solana/spl-token";
import { ActiveSwapRequest, SubmitSignedTransactionResponse, SwapType } from "../types";
import { SwapService } from "./SwapService";

export type TransactionRegistryEntry = {
  message: MessageV0;
  timestamp: number;
  swapType: SwapType;
  autoSlippage: boolean;
  contextSlot: number;
  buildAttempts: number;
  activeSwapRequest?: ActiveSwapRequest;
  cfg?: Config;
};

/**
 * Service for handling all transaction-related operations
 */
export class TransactionService {
  private messageRegistry: Map<string, TransactionRegistryEntry> = new Map();
  private swapService?: SwapService;

  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
  ) {
    this.initializeCleanup();
  }

  setSwapService(swapService: SwapService) {
    if (this.swapService) {
      throw new Error("SwapService can only be set once");
    }
    this.swapService = swapService;
  }

  private initializeCleanup(): void {
    (async () => {
      const cfg = await config();
      setInterval(() => this.cleanupRegistry(), cfg.CLEANUP_INTERVAL);
    })();
  }

  private async cleanupRegistry() {
    const cfg = await config();
    const now = Date.now();
    for (const [key, value] of this.messageRegistry.entries()) {
      if (now - value.timestamp > cfg.REGISTRY_TIMEOUT) {
        this.messageRegistry.delete(key);
      }
    }
  }

  /**
   * Builds a transaction message from instructions
   */
  async buildTransactionMessage(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
  ): Promise<MessageV0> {
    const { blockhash } = await this.connection.getLatestBlockhash();

    const message = new TransactionMessage({
      payerKey: this.feePayerKeypair.publicKey,
      recentBlockhash: blockhash,
      instructions,
    }).compileToV0Message(addressLookupTableAccounts);

    try {
      message.serialize();
    } catch (error) {
      console.error("[buildTransactionMessage] Failed to serialize message:", error);
      throw error;
    }

    return message;
  }

  /**
   * Registers a transaction message in the registry
   */
  registerTransaction(
    message: MessageV0,
    swapType: SwapType,
    autoSlippage: boolean,
    contextSlot: number,
    buildAttempts: number,
    activeSwapRequest?: ActiveSwapRequest,
    cfg?: Config,
  ): string {
    const base64Message = Buffer.from(message.serialize()).toString("base64");
    this.messageRegistry.set(base64Message, {
      message,
      timestamp: Date.now(),
      swapType,
      autoSlippage,
      contextSlot,
      buildAttempts,
      activeSwapRequest,
      cfg,
    });
    return base64Message;
  }

  /**
   * Gets a registered transaction from the registry
   */
  getRegisteredTransaction(base64Message: string): TransactionRegistryEntry | undefined {
    return this.messageRegistry.get(base64Message);
  }

  /**
   * Removes a transaction from the registry
   */
  deleteFromRegistry(base64Message: string): void {
    this.messageRegistry.delete(base64Message);
  }

  /**
   * Signs a transaction with the fee payer
   */
  async signTransaction(transaction: VersionedTransaction): Promise<string> {
    try {
      transaction.sign([this.feePayerKeypair]);
      const signature = transaction.signatures[0];
      if (!signature) {
        throw new Error("No signature found after signing");
      }
      return bs58.encode(signature);
    } catch (e) {
      console.error("[signTransaction] Error signing transaction:", e);
      throw new Error("Failed to sign transaction");
    }
  }

  /**
   * Signs and sends a transaction
   */
  async signAndSendTransaction(
    userPublicKey: PublicKey,
    userSignature: string,
    base64Message: string,
    cfg: Config,
  ): Promise<SubmitSignedTransactionResponse> {
    const entry = this.messageRegistry.get(base64Message);
    if (!entry) {
      throw new Error("Transaction not found in registry");
    }
    const transaction = new VersionedTransaction(entry.message);

    // Add user signature
    const userSignatureBytes = Buffer.from(userSignature, "base64");
    transaction.addSignature(userPublicKey, userSignatureBytes);

    // Add fee payer signature
    const feePayerSignature = await this.signTransaction(transaction);
    const feePayerSignatureBytes = Buffer.from(bs58.decode(feePayerSignature));
    transaction.addSignature(this.feePayerKeypair.publicKey, feePayerSignatureBytes);

    let txid: string = "";

    try {
      console.log("Signature Verification + Slippage Simulation");

      // resimulating, not rebuilding
      const simulation = await this.simulateTransactionWithResim(transaction, entry.contextSlot, true, false);
      if (simulation.value?.err) {
        throw new Error(JSON.stringify(simulation.value.err));
      }

      // Send and confirm transaction
      txid = await this.connection.sendTransaction(transaction, {
        skipPreflight: false,
        maxRetries: 3,
        preflightCommitment: "processed",
        minContextSlot: entry.contextSlot,
      });
    } catch (error) {
      console.log("Tx send failed: " + JSON.stringify(error));

      // don't rebuild transfer swaps
      if (entry.swapType === SwapType.TRANSFER) {
        throw new Error(JSON.stringify(error));
      }

      // TODO: error interpretation

      // don't rebuild if slippage is not auto
      if (entry.buildAttempts + 1 >= cfg.MAX_BUILD_ATTEMPTS || !entry.autoSlippage) {
        throw new Error(JSON.stringify(error));
      }

      // rebuild
      if (!this.swapService) {
        throw new Error("SwapService is not set");
      }
      if (!entry.activeSwapRequest) {
        throw new Error("ActiveSwapRequest is not set");
      }
      if (!entry.cfg) {
        throw new Error("Config is not set");
      }
      const rebuiltSwapResponse = await this.swapService.buildSwapResponse(
        entry.activeSwapRequest,
        entry.cfg,
        entry.buildAttempts,
      );
      return { responseType: "rebuild", rebuild: rebuiltSwapResponse };
    }

    let confirmation = null;
    for (let attempt = 0; attempt < cfg.CONFIRM_ATTEMPTS; attempt++) {
      console.log(`Tx Confirmation Attempt ${attempt + 1} of ${cfg.CONFIRM_ATTEMPTS}`);
      try {
        const status = await this.connection.getSignatureStatus(txid, {
          searchTransactionHistory: true,
        });

        const acceptedStates: TransactionConfirmationStatus[] = ["confirmed", "finalized", "processed"];

        if (status.value?.confirmationStatus && acceptedStates.includes(status.value.confirmationStatus)) {
          confirmation = status;
          break; // Exit loop if successful
        }
      } catch (error) {
        console.log(`Attempt ${attempt + 1} failed:`, error);
        if (attempt === cfg.CONFIRM_ATTEMPTS - 1)
          throw new Error(`Failed to get transaction confirmation after ${cfg.CONFIRM_ATTEMPTS} attempts`);
      }
      await new Promise((resolve) => setTimeout(resolve, cfg.CONFIRM_ATTEMPT_DELAY)); // Wait 1 second before next attempt
    }

    if (!confirmation) {
      throw new Error(`Transaction timed out.`);
    }
    if (confirmation.value?.err) {
      throw new Error(`Transaction failed: ${JSON.stringify(confirmation?.value?.err)}`);
    }

    this.messageRegistry.delete(base64Message);
    let timestamp: number | null = null;
    if (confirmation.value?.slot) {
      try {
        timestamp = await this.connection.getBlockTime(confirmation.value.slot);
      } catch (error) {
        console.error("[signAndSendTransaction] Error getting block time:", error);
      }
    }

    return { responseType: "success", txid, timestamp };
  }

  /**
   * Reassigns rent payer in instructions to the fee payer
   */
  reassignRentInstructions(instructions: TransactionInstruction[]): TransactionInstruction[] {
    return instructions.map((instruction) => {
      // If this is an ATA creation instruction, modify it to make fee payer pay for rent
      if (instruction.programId.equals(ATA_PROGRAM_PUBLIC_KEY)) {
        return new TransactionInstruction({
          programId: instruction.programId,
          keys: [
            {
              pubkey: this.feePayerKeypair.publicKey,
              isSigner: true,
              isWritable: true,
            },
            ...instruction.keys.slice(1),
          ],
          data: instruction.data,
        });
      }

      // This is a CloseAccount instruction, receive the residual funds as the FeePayer
      if (
        instruction.programId.equals(TOKEN_PROGRAM_PUBLIC_KEY) &&
        instruction.data.length === 1 &&
        instruction.data[0] === 9
      ) {
        const firstKey = instruction.keys[0];
        if (!firstKey) {
          throw new Error("Invalid instruction: missing account key at index 0");
        }

        return new TransactionInstruction({
          programId: instruction.programId,
          keys: [
            firstKey,
            {
              pubkey: this.feePayerKeypair.publicKey,
              isSigner: false,
              isWritable: true,
            },
            ...instruction.keys.slice(2),
          ],
          data: instruction.data,
        });
      }

      return instruction;
    });
  }

  /**
   * Optimizes compute budget instructions by estimating the compute units and setting a reasonable compute unit price
   * @param instructions - The instructions to optimize
   * @param addressLookupTableAccounts - The address lookup table accounts
   * @param cfg - Config
   * @returns The optimized instructions
   */
  async optimizeComputeInstructions(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
    contextSlot: number,
    cfg: Config,
  ): Promise<TransactionInstruction[]> {
    const { initComputeUnitPrice, filteredInstructions } = this.filterComputeInstructions(instructions, cfg);

    const simulatedComputeUnits = await this.getSimulationComputeUnits(
      filteredInstructions,
      addressLookupTableAccounts,
      contextSlot,
    );

    const estimatedComputeUnitLimit = Math.ceil(simulatedComputeUnits * 1.1);

    // use the least expensive compute unit price, note microLamports is the price per compute unit
    const MAX_COMPUTE_PRICE = cfg.MAX_COMPUTE_PRICE;
    const AUTO_PRIO_MULT = cfg.AUTO_PRIORITY_FEE_MULTIPLIER;
    const computePrice =
      initComputeUnitPrice * AUTO_PRIO_MULT < MAX_COMPUTE_PRICE
        ? initComputeUnitPrice * AUTO_PRIO_MULT
        : MAX_COMPUTE_PRICE;

    // Add the new compute unit limit and price instructions to the beginning of the instructions array
    filteredInstructions.unshift(ComputeBudgetProgram.setComputeUnitPrice({ microLamports: computePrice }));
    filteredInstructions.unshift(ComputeBudgetProgram.setComputeUnitLimit({ units: estimatedComputeUnitLimit }));

    return filteredInstructions;
  }

  /**
   * Creates a token close instruction if needed
   */
  async createTokenCloseInstruction(
    userPublicKey: PublicKey,
    tokenAccount: PublicKey,
    sellTokenId: PublicKey,
    sellQuantity: number,
    swapType: SwapType,
  ): Promise<TransactionInstruction | null> {
    // Skip if user is not selling their entire memecoin stack
    if (swapType !== SwapType.SELL_ALL) {
      return null;
    }

    // Check if the sell quantity is equal to the token account balance
    const balance = await this.getTokenBalance(userPublicKey, sellTokenId);
    if (sellQuantity === balance) {
      const closeInstruction = createCloseAccountInstruction(
        tokenAccount,
        this.feePayerKeypair.publicKey,
        userPublicKey,
      );
      return closeInstruction;
    }
    return null;
  }

  async simulateTransactionWithResim(
    transaction: VersionedTransaction,
    contextSlot: number,
    sigVerify: boolean,
    replaceRecentBlockhash: boolean,
  ): Promise<RpcResponseAndContext<SimulatedTransactionResponse>> {
    // Try simulation multiple times
    const cfg = await config();

    for (let attempt = 0; attempt < cfg.MAX_SIM_ATTEMPTS; attempt++) {
      try {
        const response = await this.connection.simulateTransaction(transaction, {
          replaceRecentBlockhash: replaceRecentBlockhash,
          sigVerify: sigVerify,
          commitment: "processed",
          minContextSlot: contextSlot,
        });
        if (response.value.err) {
          throw new Error(JSON.stringify(response.value.err));
        }
        return response;
      } catch (error) {
        console.log(`Simulation attempt ${attempt + 1}/${cfg.MAX_SIM_ATTEMPTS} failed:`, error);
        if (attempt === cfg.MAX_SIM_ATTEMPTS - 1) {
          throw new Error(JSON.stringify(error));
        }
        await new Promise((resolve) => setTimeout(resolve, 100));
        continue;
      }
    }
    // this should never happen
    throw new Error("Simulation failed after all attempts. No error was provided");
  }

  async getTokenBalance(userPublicKey: PublicKey, tokenMint: PublicKey): Promise<number> {
    const tokenAccounts = await this.connection.getParsedTokenAccountsByOwner(
      userPublicKey,
      { mint: new PublicKey(tokenMint) },
      "processed",
    );

    if (tokenAccounts.value.length === 0 || !tokenAccounts.value[0]?.account.data.parsed.info.tokenAmount.amount)
      return 0;

    const balance = Number(tokenAccounts.value[0].account.data.parsed.info.tokenAmount.amount);
    return balance;
  }

  private async getSimulationComputeUnits(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
    contextSlot: number,
  ): Promise<number> {
    const simulatedInstructions = [
      // Set max limit in simulation so tx succeeds and the necessary compute unit limit can be calculated
      ComputeBudgetProgram.setComputeUnitLimit({ units: MAX_CHAIN_COMPUTE_UNITS }),
      ...instructions,
    ];

    const testTransaction = new VersionedTransaction(
      new TransactionMessage({
        instructions: simulatedInstructions,
        payerKey: this.feePayerKeypair.publicKey,
        recentBlockhash: PublicKey.default.toString(), // doesn't matter due to replaceRecentBlockhash
      }).compileToV0Message(addressLookupTableAccounts),
    );

    console.log("Compute Unit Simulation");

    const rpcResponse = await this.simulateTransactionWithResim(testTransaction, contextSlot, false, true);

    if (!rpcResponse.value.unitsConsumed) {
      throw new Error("Transaction sim returned undefined unitsConsumed");
    }

    return rpcResponse.value.unitsConsumed;
  }

  private filterComputeInstructions(instructions: TransactionInstruction[], cfg: Config) {
    const computeUnitLimitIndex = instructions.findIndex(
      (ix) => ix.programId.equals(ComputeBudgetProgram.programId) && ix.data[0] === 0x02,
    );
    const computeUnitPriceIndex = instructions.findIndex(
      (ix) => ix.programId.equals(ComputeBudgetProgram.programId) && ix.data[0] === 0x03,
    );

    const initComputeUnitPrice =
      computeUnitPriceIndex >= 0
        ? Number(ComputeBudgetInstruction.decodeSetComputeUnitPrice(instructions[computeUnitPriceIndex]!).microLamports)
        : cfg.MAX_COMPUTE_PRICE; // the "!" is redundant, as we just found it above and `>= 0` check ensures it's exists. Just satisfies the linter.

    // Remove the initial compute unit limit and price instructions, handling the case where removing the first affects the index of the second
    const filteredInstructions = instructions.filter(
      (_, index) => index !== computeUnitLimitIndex && index !== computeUnitPriceIndex,
    );

    return {
      initComputeUnitPrice,
      filteredInstructions,
    };
  }
}
