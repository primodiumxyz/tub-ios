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
      const {
        swaps: swapsWithData,
        accountsLatency,
        pricesLatency,
      } = await fetchPriceAndMetadata(this.connection, batchToProcess);
      const upsertStartTime = Date.now();
      const res = await upsertTrades(this.gql, swapsWithData);
      if (res.error) throw res.error.message;

      this.logBatchMetrics({
        batchSize: batchToProcess.length,
        affectedRows: res.data?.insert_api_trade_history?.affected_rows ?? 0,
        queueLatency,
        accountsLatency,
        pricesLatency,
        upsertLatency: (Date.now() - upsertStartTime) / 1000,
      });
    } catch (error) {
      console.error("Error processing batch:", error);
      this.batch.unshift(...batchToProcess);
    } finally {
      this.processing = false;
    }
  }

  private logBatchMetrics({
    batchSize,
    affectedRows,
    queueLatency,
    accountsLatency,
    pricesLatency,
    upsertLatency,
  }: {
    batchSize: number;
    affectedRows: number;
    queueLatency: number;
    accountsLatency: number;
    pricesLatency: number;
    upsertLatency: number;
  }) {
    console.log(
      [
        "\n=== Batch Processing Metrics ===",
        `Batch size: ${batchSize} | Affected rows: ${affectedRows}`,
        `Queue latency: ${queueLatency.toFixed(2)}s`,
        `Fetch accounts latency: ${accountsLatency.toFixed(2)}s`,
        `Fetch prices latency: ${pricesLatency.toFixed(2)}s`,
        `Upsert latency: ${upsertLatency.toFixed(2)}s`,
        `Total processing time: ${(queueLatency + accountsLatency + pricesLatency + upsertLatency).toFixed(2)}s`,
        "================================\n",
      ].join("\n"),
    );
  }

  cleanup() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }
}
