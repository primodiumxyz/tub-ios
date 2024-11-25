import { GqlClient } from "@tub/gql";
import { MAX_BATCH_SIZE, MIN_BATCH_FREQUENCY } from "@/lib/constants";
import { Swap, SwapType } from "@/lib/types";
import { fetchPriceData, upsertTrades } from "@/lib/utils";

export class BatchManager {
  private batch: Swap<SwapType>[] = [];
  private lastProcessTime: number = 0;
  private processing: boolean = false;
  private timer: NodeJS.Timeout | null = null;

  constructor(private gql: GqlClient["db"]) {
    // Start the timer to check for processing needs periodically
    this.timer = setInterval(() => {
      this.processIfNeeded();
    }, MIN_BATCH_FREQUENCY);
  }

  async add(swaps: Swap<SwapType>[]) {
    this.batch.push(...swaps);
    await this.processIfNeeded();
  }

  private async processIfNeeded() {
    if (this.processing || this.batch.length === 0) return;

    const now = Date.now();
    const shouldProcessTime = this.lastProcessTime === 0 || now - this.lastProcessTime >= MIN_BATCH_FREQUENCY;
    const shouldProcessSize = this.batch.length >= MAX_BATCH_SIZE;

    if (shouldProcessTime || shouldProcessSize) {
      this.processing = true;
      try {
        const batchToProcess = [...this.batch];
        this.batch = [];
        this.lastProcessTime = now;

        const swapWithPriceData = await fetchPriceData(batchToProcess);
        await upsertTrades(this.gql, swapWithPriceData);

        console.log(`Processed batch of ${batchToProcess.length} swaps`);
      } catch (error) {
        console.error("Error processing batch:", error);
        // On error, add items back to batch
        this.batch = [...this.batch, ...this.batch];
      }
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
