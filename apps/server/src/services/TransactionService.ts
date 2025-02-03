import { createCloseAccountInstruction } from "@solana/spl-token";
import {
  AddressLookupTableAccount,
  ComputeBudgetInstruction,
  ComputeBudgetProgram,
  Connection,
  Keypair,
  MessageV0,
  PublicKey,
  TransactionConfirmationStatus,
  TransactionInstruction,
  TransactionMessage,
  VersionedTransaction,
  RpcResponseAndContext,
  SimulatedTransactionResponse,
  SignatureStatus,
} from "@solana/web3.js";
import bs58 from "bs58";
import {
  ATA_PROGRAM_PUBLIC_KEY,
  MAX_CHAIN_COMPUTE_UNITS,
  TOKEN_PROGRAM_PUBLIC_KEY,
  USDC_MAINNET_PUBLIC_KEY,
} from "../constants/tokens";
import {
  ActiveSwapRequest,
  SubmitSignedTransactionResponse,
  TransactionType,
  TransactionRegistryEntry,
  TransactionRegistryData,
} from "../types";
import { config } from "../utils/config";
import { Config } from "./ConfigService";

/**
 * Service for handling all transaction-related operations
 * Manages transaction building, signing, simulation, and registry operations
 */
export class TransactionService {
  /** Registry to store transaction messages and their metadata */
  private messageRegistry: Map<string, TransactionRegistryEntry> = new Map();

  /**
   * Creates a new TransactionService instance
   * @param connection - Solana RPC connection
   * @param feePayerKeypair - Keypair used for paying transaction fees
   */
  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
  ) {
    this.initializeCleanup();
  }

  // ----------- Initialization ------------

  /**
   * Initializes periodic cleanup of the transaction registry
   * @private
   */
  private initializeCleanup(): void {
    (async () => {
      const cfg = await config();
      setInterval(() => this.cleanupRegistry(), cfg.CLEANUP_INTERVAL);
    })();
  }

  /**
   * Cleans up expired transactions from the registry
   * @private
   */
  private async cleanupRegistry() {
    const cfg = await config();
    const now = Date.now();
    for (const [key, value] of this.messageRegistry.entries()) {
      if (now - value.timestamp > cfg.REGISTRY_TIMEOUT) {
        this.messageRegistry.delete(key);
      }
    }
  }

  // ----------- Transaction Registry ------------

  /**
   * Gets a registered transaction from the registry
   * @param base64Message - Base64 encoded transaction message
   * @returns Transaction registry entry if found, undefined otherwise
   */
  getRegisteredTransaction(base64Message: string): TransactionRegistryEntry | undefined {
    return this.messageRegistry.get(base64Message);
  }

  /**
   * Removes a transaction from the registry
   * @param base64Message - Base64 encoded transaction message to delete
   */
  deleteFromRegistry(base64Message: string): void {
    this.messageRegistry.delete(base64Message);
  }

  /**
   * Registers a transaction message in the registry
   * @param message - Transaction message to register
   * @param lastValidBlockHeight - Last valid block height for the transaction
   * @param transactionType - Type of transaction (BUY, SELL_ALL, SELL_PARTIAL, TRANSFER)
   * @param autoSlippage - Whether auto slippage is enabled
   * @param contextSlot - Current slot context
   * @param buildAttempts - Number of build attempts made
   * @param activeSwapRequest - Optional active swap request details
   * @param cfg - Optional configuration settings
   * @returns Base64 encoded transaction message
   */
  registerTransaction(
    message: MessageV0,
    lastValidBlockHeight: number,
    transactionType: TransactionType,
    autoSlippage: boolean,
    contextSlot: number,
    buildAttempts: number,
    activeSwapRequest?: ActiveSwapRequest,
    cfg?: Config,
  ): string {
    const base64Message = Buffer.from(message.serialize()).toString("base64");
    this.messageRegistry.set(base64Message, {
      message,
      lastValidBlockHeight,
      timestamp: Date.now(),
      transactionType,
      autoSlippage,
      contextSlot,
      buildAttempts,
      activeSwapRequest,
      cfg,
    });
    return base64Message;
  }

  // ----------- Transaction Operations ------------

  /**
   * Builds a transaction message from instructions and registers it in the registry
   * @param instructions - Transaction instructions to build
   * @param addressLookupTableAccounts - Address lookup table accounts
   * @param txRegistryData - Transaction registry metadata
   * @returns Base64 encoded transaction message
   */
  async buildAndRegisterTransactionMessage(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
    txRegistryData: TransactionRegistryData,
  ): Promise<string> {
    const { message, lastValidBlockHeight } = await this.buildTransactionMessage(
      instructions,
      addressLookupTableAccounts,
    );

    // Register transaction
    const base64Message = this.registerTransaction(
      message,
      lastValidBlockHeight,
      txRegistryData.transactionType,
      txRegistryData.autoSlippage,
      txRegistryData.contextSlot,
      txRegistryData.buildAttempts,
      txRegistryData.activeSwapRequest,
      txRegistryData.cfg,
    );

    return base64Message;
  }

  /**
   * Builds a transaction message from instructions
   * @param instructions - Transaction instructions to build
   * @param addressLookupTableAccounts - Address lookup table accounts
   * @returns Transaction message, blockhash, and last valid block height
   * @throws Error if message serialization fails
   */
  async buildTransactionMessage(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
  ): Promise<{ message: MessageV0; blockhash: string; lastValidBlockHeight: number }> {
    const { blockhash, lastValidBlockHeight } = await this.connection.getLatestBlockhash();

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

    return { message, blockhash, lastValidBlockHeight };
  }

  /**
   * Signs a transaction with the fee payer
   * @param transaction - Transaction to sign
   * @returns Base58 encoded signature
   * @throws Error if signing fails or no signature is found
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
   * @param userPublicKey - User's public key
   * @param userSignature - User's transaction signature
   * @param entry - Transaction registry entry
   * @param cfg - Configuration settings
   * @returns Transaction submission response
   * @throws Error if transaction simulation or sending fails
   */
  async signAndSendTransaction(
    userPublicKey: PublicKey,
    userSignature: string,
    entry: TransactionRegistryEntry,
    cfg: Config,
  ): Promise<SubmitSignedTransactionResponse> {
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

      // Send transaction
      txid = await this.connection.sendTransaction(transaction, {
        skipPreflight: false,
        preflightCommitment: "processed",
        minContextSlot: entry.contextSlot,
      });
    } catch (error) {
      console.log("Tx send failed: " + JSON.stringify(error));
      throw new Error(JSON.stringify(error));
    }

    // tx confirmation and resend case
    try {
      const confirmation = await this.confirmTransaction(txid, entry.lastValidBlockHeight, cfg);
      const base64Message = Buffer.from(entry.message.serialize()).toString("base64");
      this.deleteFromRegistry(base64Message);
      let timestamp: number | null = null;
      if (confirmation.value?.slot) {
        for (let attempt = 0; attempt < cfg.CONFIRM_ATTEMPTS / 2 && !timestamp; attempt++) {
          try {
            timestamp = await this.connection.getBlockTime(confirmation.value.slot);
          } catch (error) {
            console.error("[signAndSendTransaction] Error getting block time:", error);
            await new Promise((resolve) => setTimeout(resolve, cfg.CONFIRM_ATTEMPT_DELAY)); // Wait 1 second before next attempt
          }
        }
      }
      return { responseType: "success", txid, timestamp };
    } catch (error) {
      console.error("[signAndSendTransaction] Error confirming transaction:", error);
      const response: SubmitSignedTransactionResponse = { responseType: "fail", error: JSON.stringify(error) };
      return response;
    }
  }

  /**
   * Confirms a transaction
   * @param txid - Transaction ID
   * @param lastValidBlockHeight - Last valid block height
   * @param cfg - Configuration settings
   * @returns Transaction confirmation status
   * @throws Error if transaction expires or confirmation fails
   */
  async confirmTransaction(
    txid: string,
    lastValidBlockHeight: number,
    cfg: Config,
  ): Promise<RpcResponseAndContext<SignatureStatus>> {
    const AVG_BLOCK_TIME = 400; // ms
    let blockHeight: number = 0;
    let attempt = 0;

    do {
      blockHeight = await this.connection.getBlockHeight({ commitment: "confirmed" });
      const estimatedTimeTillExpiry = (lastValidBlockHeight - blockHeight) * AVG_BLOCK_TIME;
      const timeToRecheckBlockHeight = Date.now() + estimatedTimeTillExpiry;
      do {
        console.log(`Tx Confirmation Attempt ${attempt + 1}`);
        try {
          const status = await this.connection.getSignatureStatus(txid, {
            searchTransactionHistory: true,
          });

          const acceptedStates: TransactionConfirmationStatus[] = ["confirmed", "finalized"]; // processed is not accepted, 5% orphan chance

          if (status.value?.confirmationStatus && acceptedStates.includes(status.value.confirmationStatus)) {
            return status as RpcResponseAndContext<SignatureStatus>;
          }

          if (status.value?.err) {
            console.error("[confirmTransaction] Error getting transaction confirmation:", status.value.err);
          }
        } catch (error) {
          console.log(`Attempt ${attempt + 1} failed:`, error);
        }
        await new Promise((resolve) => setTimeout(resolve, cfg.CONFIRM_ATTEMPT_DELAY)); // Wait 1 second before next attempt
        attempt++;
      } while (Date.now() < timeToRecheckBlockHeight);
    } while (blockHeight <= lastValidBlockHeight);

    throw new Error("Transaction expired");
  }

  /**
   * Simulates a transaction with retry logic
   * @param transaction - Transaction to simulate
   * @param contextSlot - Current slot context
   * @param sigVerify - Whether to verify signatures
   * @param replaceRecentBlockhash - Whether to replace recent blockhash
   * @returns Simulation response
   * @throws Error if simulation fails after all attempts
   */
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
        await new Promise((resolve) => setTimeout(resolve, 300));
        continue;
      }
    }
    // this should never happen
    throw new Error("Simulation failed after all attempts. No error was provided");
  }

  /**
   * Gets simulation compute units for a transaction
   * @param instructions - Transaction instructions
   * @param addressLookupTableAccounts - Address lookup table accounts
   * @param contextSlot - Current slot context
   * @returns Number of compute units used
   * @throws Error if simulation fails or returns undefined units
   * @private
   */
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

    // log the instructions
    console.log(simulatedInstructions);
    console.log("Compute Unit Simulation");

    const rpcResponse = await this.simulateTransactionWithResim(testTransaction, contextSlot, false, true);

    if (!rpcResponse.value.unitsConsumed) {
      throw new Error("Transaction sim returned undefined unitsConsumed");
    }

    return rpcResponse.value.unitsConsumed;
  }

  // ----------- Instruction Modification ------------

  /**
   * Filters compute budget instructions from an instruction array
   * @param instructions - Instructions to filter
   * @param cfg - Configuration settings
   * @returns Filtered instructions and initial compute unit price
   * @private
   */
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

  /**
   * Optimizes compute budget instructions by estimating the compute units and setting a reasonable compute unit price
   * @param instructions - Instructions to optimize
   * @param addressLookupTableAccounts - Address lookup table accounts
   * @param contextSlot - Current slot context
   * @param cfg - Configuration settings
   * @returns Optimized instructions with compute budget
   */
  async optimizeComputeInstructions(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
    contextSlot: number,
    cfg: Config,
  ): Promise<TransactionInstruction[]> {
    const { initComputeUnitPrice, filteredInstructions } = this.filterComputeInstructions(instructions, cfg);

    console.log({
      initComputeUnitPrice,
      filteredInstructions,
    });

    const simulatedComputeUnits = await this.getSimulationComputeUnits(
      filteredInstructions,
      addressLookupTableAccounts,
      contextSlot,
    );

    console.log("first simulation done");

    const estimatedComputeUnitLimit = Math.ceil(simulatedComputeUnits * 1.1);

    // use the least expensive compute unit price, note microLamports is the price per compute unit
    const MAX_COMPUTE_PRICE = cfg.MAX_COMPUTE_PRICE;
    const AUTO_PRIO_MULT = cfg.AUTO_PRIORITY_FEE_MULTIPLIER;
    const computePrice =
      initComputeUnitPrice * AUTO_PRIO_MULT < MAX_COMPUTE_PRICE
        ? initComputeUnitPrice * AUTO_PRIO_MULT
        : MAX_COMPUTE_PRICE;

    console.log({
      initComputeUnitPrice,
      AUTO_PRIO_MULT,
      MAX_COMPUTE_PRICE,
      computePrice,
    });

    // Add the new compute unit limit and price instructions to the beginning of the instructions array
    filteredInstructions.unshift(ComputeBudgetProgram.setComputeUnitPrice({ microLamports: computePrice }));
    filteredInstructions.unshift(ComputeBudgetProgram.setComputeUnitLimit({ units: estimatedComputeUnitLimit }));

    return filteredInstructions;
  }

  /**
   * Reassigns rent payer in instructions to the fee payer
   * @param instructions - Instructions to modify
   * @returns Modified instructions with reassigned rent payer
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
   * Creates a token close instruction if needed
   * @param userPublicKey - User's public key
   * @param tokenAccount - Token account to close
   * @param sellTokenId - Token being sold
   * @param sellQuantity - Amount being sold
   * @param transactionType - Type of transaction
   * @returns Close instruction if needed, null otherwise
   */
  async createTokenCloseInstruction(
    userPublicKey: PublicKey,
    tokenAccount: PublicKey,
    sellTokenId: PublicKey,
    sellQuantity: number,
    transactionType: TransactionType,
  ): Promise<TransactionInstruction | null> {
    // Skip if user is not selling their entire memecoin stack
    if (transactionType !== TransactionType.SELL_ALL) {
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

  /**
   * Determines the type of transaction based on the swap request
   * @param request - Active swap request
   * @returns Transaction type (BUY, SELL_ALL, SELL_PARTIAL)
   * @throws Error if sell token balance is insufficient
   */
  async determineTransactionType(request: ActiveSwapRequest): Promise<TransactionType> {
    if (request.buyTokenId === USDC_MAINNET_PUBLIC_KEY.toString()) {
      const sellTokenBalance = await this.connection.getTokenAccountBalance(request.sellTokenAccount, "processed");
      if (!sellTokenBalance.value.amount) {
        throw new Error("Sell token balance is null");
      }
      // if balance is greater than sellQuantity, return SELL_PARTIAL
      if (Number(sellTokenBalance.value.amount) > request.sellQuantity) {
        return TransactionType.SELL_PARTIAL;
      }
      // if balance is equal to sellQuantity, return SELL_ALL
      if (Number(sellTokenBalance.value.amount) === request.sellQuantity) {
        return TransactionType.SELL_ALL;
      }
      // otherwise, throw error as not enough balance. show balance in thrown error.
      throw new Error(`Not enough memecoin balance. Observed balance: ${Number(sellTokenBalance.value.uiAmount)}`);
    } else {
      return TransactionType.BUY;
    }
  }

  /**
   * Gets the balance of a token account
   * @param userPublicKey - User's public key
   * @param tokenMint - Token mint address
   * @returns Token balance in base units
   */
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
}
