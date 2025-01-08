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
} from "@solana/web3.js";
import bs58 from "bs58";
import { config } from "../utils/config";
import { ATA_PROGRAM_PUBLIC_KEY, JUPITER_PROGRAM_PUBLIC_KEY, TOKEN_PROGRAM_PUBLIC_KEY } from "../constants/tokens";
import { Config } from "./ConfigService";
import { createCloseAccountInstruction } from "@solana/spl-token";
import { SwapType } from "../types";

export type TransactionRegistryEntry = {
  message: MessageV0;
  timestamp: number;
};

/**
 * Service for handling all transaction-related operations
 */
export class TransactionService {
  private messageRegistry: Map<string, TransactionRegistryEntry> = new Map();

  constructor(
    private connection: Connection,
    private feePayerKeypair: Keypair,
  ) {
    this.initializeCleanup();
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
  registerTransaction(message: MessageV0): string {
    const base64Message = Buffer.from(message.serialize()).toString("base64");
    this.messageRegistry.set(base64Message, {
      message,
      timestamp: Date.now(),
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
  ): Promise<{ signature: string; timestamp: number | null }> {
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

    const simulation = await this.connection.simulateTransaction(transaction, {
      commitment: "processed",
      replaceRecentBlockhash: true,
    });

    if (simulation.value?.err) {
      console.log("Local Simulation Error:", simulation.value);
      if (simulation.value.err.toString().includes("InstructionError")) {
        const errorStr = JSON.stringify(simulation.value.err);
        const match = errorStr.match(/\{"InstructionError":\[(\d+)/);
        const failedInstructionIndex = match?.[1] ? parseInt(match[1]) : -1;

        if (failedInstructionIndex >= 0) {
          const failedInstruction = entry.message.compiledInstructions[failedInstructionIndex];

          if (failedInstruction) {
            const programId = entry.message.staticAccountKeys[failedInstruction.programIdIndex];

            console.log("Failed Instruction Details:", {
              programId: programId!.toBase58(),
              accounts: failedInstruction.accountKeyIndexes.map((index) =>
                entry.message.staticAccountKeys[index]!.toBase58(),
              ),
              data: Buffer.from(failedInstruction.data).toString("hex"),
            });

            let errorMessage = `Tx sim failed: ${errorStr}`;

            if (programId === TOKEN_PROGRAM_PUBLIC_KEY) {
              errorMessage = `Sim failed, Token Program Error: ${errorStr}`; // This usually means there's an issue with token accounts or balances.
            } else if (programId === ATA_PROGRAM_PUBLIC_KEY) {
              errorMessage = `Sim failed, ATA Error: ${errorStr}`; // This usually means there's an issue creating or accessing a token account.
            } else if (programId === JUPITER_PROGRAM_PUBLIC_KEY) {
              if (errorStr.includes("6001")) {
                errorMessage = `Sim failed, Slippage Tolerance Exceeded`;
              } else {
                errorMessage = `Sim failed, Jupiter Program Error: ${errorStr}`; // This usually indicates an issue with the swap parameters or market conditions.
              }
            }

            throw new Error(errorMessage);
          }
        }
      }
      throw new Error(`Transaction simulation failed: ${JSON.stringify(simulation.value.err)}`);
    }

    // Send and confirm transaction
    const txid = await this.connection.sendTransaction(transaction, {
      skipPreflight: false,
      maxRetries: 3,
      preflightCommitment: "processed",
    });

    let confirmation = null;
    for (let attempt = 0; attempt < cfg.RETRY_ATTEMPTS; attempt++) {
      console.log(`Tx Confirmation Attempt ${attempt + 1} of ${cfg.RETRY_ATTEMPTS}`);
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
        if (attempt === cfg.RETRY_ATTEMPTS - 1)
          throw new Error(`Failed to get transaction confirmation after ${cfg.RETRY_ATTEMPTS} attempts`);
      }
      await new Promise((resolve) => setTimeout(resolve, cfg.RETRY_DELAY)); // Wait 1 second before retrying
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

    return { signature: txid, timestamp };
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
   * @returns The optimized instructions
   */
  async optimizeComputeInstructions(
    instructions: TransactionInstruction[],
    addressLookupTableAccounts: AddressLookupTableAccount[],
  ): Promise<TransactionInstruction[]> {
    // get current instructions compute unit price. first instruction is compute unit limit, second is compute unit price
    const initialComputeUnitPrice = Number(
      ComputeBudgetInstruction.decodeSetComputeUnitPrice(instructions[1]!).microLamports,
    );

    // remove the previous compute unit limit and price in the instructions array
    const slicedInstructions = instructions.slice(2);
    const simulatedComputeUnits = await this.getSimulationComputeUnits(slicedInstructions, addressLookupTableAccounts);

    if (!simulatedComputeUnits) {
      throw new Error("Failed to estimate compute units");
    }

    const estimatedComputeUnitLimit = Math.ceil(simulatedComputeUnits * 1.1);

    // use the least expensive compute unit price, note microLamports is the price per compute unit
    const MAX_COMPUTE_PRICE = 1e6;
    const computePrice =
      initialComputeUnitPrice * 2 < MAX_COMPUTE_PRICE ? initialComputeUnitPrice * 2 : MAX_COMPUTE_PRICE;

    instructions[0] = ComputeBudgetProgram.setComputeUnitLimit({ units: estimatedComputeUnitLimit });
    instructions[1] = ComputeBudgetProgram.setComputeUnitPrice({ microLamports: computePrice });

    return instructions;
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
  ) {
    const simulatedInstructions = [
      // Set max limit in simulation so tx succeeds and limit can be calculated
      ComputeBudgetProgram.setComputeUnitLimit({ units: 1_400_000 }),
      ...instructions,
    ];

    const testTransaction = new VersionedTransaction(
      new TransactionMessage({
        instructions: simulatedInstructions,
        payerKey: this.feePayerKeypair.publicKey,
        recentBlockhash: PublicKey.default.toString(), // doesn't matter due to replaceRecentBlockhash
      }).compileToV0Message(addressLookupTableAccounts),
    );

    // Try simulation with retries
    let rpcResponse;
    const MAX_RETRIES = 2;
    let lastError;

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        rpcResponse = await this.connection.simulateTransaction(testTransaction, {
          replaceRecentBlockhash: true,
          sigVerify: false,
          commitment: "processed",
        });
        break; // Success - exit loop
      } catch (error) {
        lastError = error;
        console.log(`Simulation attempt ${attempt + 1}/${MAX_RETRIES} failed:`, error);

        if (attempt < MAX_RETRIES - 1) {
          // Wait 100ms before retrying
          await new Promise((resolve) => setTimeout(resolve, 100));
        }
      }
    }

    if (!rpcResponse) {
      console.error("All simulation attempts failed");
      throw new Error(`Failed to simulate transaction after ${MAX_RETRIES} attempts: ${lastError}`);
    }

    return rpcResponse.value.unitsConsumed;
  }
}
