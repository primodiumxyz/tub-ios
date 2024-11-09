import { GqlClient } from "@tub/gql";

type QueueItem = {
  tokens: Array<{
    mint: string;
    name: string | null;
    symbol: string | null;
    description: string | null;
    uri: string | null;
    mint_burnt: boolean | null;
    freeze_burnt: boolean | null;
    supply: string | null;
    decimals: number | null;
    is_pump_token: boolean | null;
  }>;
  price_histories: Array<{
    price: string;
    amount_in: string | null;
    min_amount_out: string | null;
    max_amount_in: string | null;
    amount_out: string | null;
    created_at: Date;
  }>;
  gql: GqlClient["db"];
};

export class DatabaseQueue {
  private queue: QueueItem[] = [];
  private processing = false;

  async add(item: QueueItem) {
    this.queue.push(item);

    if (!this.processing) {
      await this.process();
    }
  }

  private async process() {
    this.processing = true;

    while (this.queue.length > 0) {
      const item = this.queue[0];
      if (!item) throw new Error("Item is undefined");
      let success = false;

      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const result = await item.gql.UpsertManyTokensAndPriceHistoriesMutation({
            tokens: item.tokens,
            price_histories: item.price_histories,
          });

          if (result.error) {
            throw new Error(result.error.message);
          }

          console.log(`Processed ${item.tokens.length} tokens with ${item.price_histories.length} price points`);
          console.log(`Time: ${item.price_histories[0]?.created_at}`);
          success = true;
          break;
        } catch (err) {
          console.error(`Attempt ${attempt + 1} failed:`, err);
          if (attempt === 2) {
            console.error("Failed to process database batch after retries:", err);
          } else {
            await new Promise((resolve) => setTimeout(resolve, Math.pow(2, attempt) * 1000));
          }
        }
      }

      if (success) {
        this.queue.shift();
      } else {
        const failedItem = this.queue.shift();
        if (failedItem) {
          this.queue.push(failedItem);
        }
      }
    }

    this.processing = false;
  }
}
