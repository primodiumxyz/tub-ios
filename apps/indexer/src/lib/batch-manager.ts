import { Connection } from "@solana/web3.js";

import { GqlClient } from "@tub/gql";
import { MAX_BATCH_SIZE, MIN_BATCH_FREQUENCY, PROCESSING_MODE, ProcessingMode } from "@/lib/constants";
import { Swap } from "@/lib/types";
import { fetchPriceAndMetadata, upsertTrades } from "@/lib/utils";

export class BatchManager {
  private batch: Swap[] = [];
  private lastProcessTime: number = 0;
  private processing: boolean = false;
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private gql: GqlClient["db"],
    private connection: Connection,
  ) {
    // Start the timer to check for processing needs periodically
    this.timer = setInterval(() => {
      this.processIfNeeded();
    }, MIN_BATCH_FREQUENCY);
  }

  async add(swaps: Swap[]) {
    this.batch.push(...swaps);
    await this.processIfNeeded();
  }

  private async processIfNeeded() {
    if (this.batch.length === 0) return;
    // Don't process if in queue mode and already processing
    if (PROCESSING_MODE === ProcessingMode.QUEUE && this.processing) return;

    const now = Date.now();
    const timeSinceLastProcess = now - this.lastProcessTime;
    const shouldProcessTime = timeSinceLastProcess >= MIN_BATCH_FREQUENCY;
    const shouldProcessSize = this.batch.length >= MAX_BATCH_SIZE;

    // Only process if EITHER:
    // 1. We've hit the max batch size
    // 2. We have items AND enough time has passed since last process
    if (!shouldProcessSize && !(this.batch.length > 0 && shouldProcessTime)) return;

    // Update last process time before processing
    this.lastProcessTime = now;

    try {
      await this.process();
    } catch (error) {
      console.error("Error processing batch:", error);
    }
  }

  private async process() {
    this.processing = true;
    const batchToProcess = this.batch.splice(0, MAX_BATCH_SIZE);
    const oldestSwapTime = Math.min(...batchToProcess.map((swap) => swap.timestamp));
    const queueLatency = (Date.now() - oldestSwapTime) / 1000;

    try {
      const latencyBefore = (Date.now() - oldestSwapTime) / 1000;
      console.log(`[${latencyBefore.toFixed(2)}s] Processing batch of ${batchToProcess.length} swaps...`);

      const SwapWithPriceAndMetadata = await fetchPriceAndMetadata(this.connection, batchToProcess);
      const res = await upsertTrades(this.gql, SwapWithPriceAndMetadata);
      if (res.error) throw res.error.message;

      const processingLatency = (Date.now() - oldestSwapTime) / 1000;
      console.log(
        `[${processingLatency.toFixed(2)}s] Processed batch of ${res.data?.insert_api_trade_history?.affected_rows} swaps`,
      );
      console.log(
        `Queue latency: ${queueLatency.toFixed(2)}s | Processing latency: ${(processingLatency - queueLatency).toFixed(2)}s`,
      );
      console.log("--------------------------------");
    } catch (error) {
      console.error("Error processing batch:", error);
      this.batch.unshift(...batchToProcess);
    } finally {
      this.processing = false;
    }
  }

  cleanup() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }
}
