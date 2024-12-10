import { initTRPC } from "@trpc/server";
import { observable } from "@trpc/server/observable";
import { z } from "zod";
import { TubService } from "./services/TubService";
import { PrebuildSwapResponse, UserPrebuildSwapRequest } from "./types";
import { Subject } from "rxjs";

export type AppContext = {
  tubService: TubService;
  jwtToken: string;
};

// Validation schemas
const swapRequestSchema = z.object({
  buyTokenId: z.string(),
  sellTokenId: z.string(),
  sellQuantity: z.number(),
}) satisfies z.ZodType<UserPrebuildSwapRequest>;

/**
 * Creates and configures the main tRPC router with all API endpoints.
 * @returns A configured tRPC router with all procedures
 */
export function createAppRouter() {
  const t = initTRPC.context<AppContext>().create();
  return t.router({
    /**
     * Health check endpoint that returns server status
     * @returns Object containing status code 200 if server is healthy
     */
    getStatus: t.procedure.query(({ ctx }) => {
      return ctx.tubService.getStatus();
    }),

    recordClientEvent: t.procedure
      .input(
        z.object({
          userAgent: z.string(),
          eventName: z.string(),
          buildVersion: z.string().optional(),
          metadata: z.string().optional(),
          errorDetails: z.string().optional(),
          source: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordClientEvent(input, ctx.jwtToken);
      }),

    requestCodexToken: t.procedure
      .input(z.object({ expiration: z.number().optional() }))
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.requestCodexToken(input.expiration);
      }),

    swapStream: t.procedure.input(z.object({ request: swapRequestSchema })).subscription(async ({ ctx, input }) => {
      return observable<PrebuildSwapResponse>((emit) => {
        let subject: Subject<PrebuildSwapResponse> | undefined;
        let cleanup: (() => void) | undefined;

        ctx.tubService
          .startSwapStream(ctx.jwtToken, input.request)
          .then((s) => {
            if (!s) {
              emit.error(new Error("Failed to start swap stream"));
              return;
            }

            subject = s;
            const subscription = subject.subscribe({
              next: (response: PrebuildSwapResponse) => {
                emit.next(response);
              },
              error: (error: Error) => {
                emit.error(error);
              },
              complete: () => {
                emit.complete();
              },
            });

            cleanup = () => {
              subscription.unsubscribe();
              subject?.complete();
            };
          })
          .catch((error) => {
            emit.error(error);
          });

        return () => {
          cleanup?.();
        };
      });
    }),

    /**
     * Creates a subscription stream for token swaps
     * @param buyTokenId - The token ID to buy
     * @param sellTokenId - The token ID to sell
     * @param sellQuantity - The amount of tokens to sell
     * @param userPublicKey - The user's Solana public key
     * @returns Observable stream of base64-encoded transactions
     * @throws Error if public key is invalid or token IDs are missing
     */
    startSwapStream: t.procedure
      .input(
        z.object({
          buyTokenId: z.string(),
          sellTokenId: z.string(),
          sellQuantity: z.number(),
        }),
      )
      .subscription(({ ctx, input }) => {
        return observable((emit) => {
          let subject = null;

          ctx.tubService
            .startSwapStream(ctx.jwtToken, input)
            .then((s) => {
              if (!s) {
                emit.error(new Error("Failed to start swap stream"));
                return;
              }
              subject = s;
              if (subject) {
                subject.subscribe({
                  next: (response: PrebuildSwapResponse) => {
                    emit.next(response);
                  },
                  error: (error: Error) => {
                    console.error("Swap stream error:", error);
                    emit.error(error);
                  },
                });
              }
            })
            .catch((error) => {
              console.error("Failed to start swap stream:", error);
              emit.error(error);
            });

          return () => {
            ctx.tubService.stopSwapStream(ctx.jwtToken).catch(console.error);
          };
        });
      }),

    /**
     * Updates an existing swap request with new parameters
     * @param buyTokenId - Optional new token ID to buy
     * @param sellTokenId - Optional new token ID to sell
     * @param sellQuantity - Optional new quantity to sell
     */
    updateSwapRequest: t.procedure
      .input(
        z.object({
          buyTokenId: z.string(),
          sellTokenId: z.string(),
          sellQuantity: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.updateSwapRequest(ctx.jwtToken, input);
      }),

    /**
     * Submits a signed transaction for processing
     * @param signature - The user's signature for the transaction
     * @param base64Transaction - The base64-encoded transaction (before signing) to submit. Came from swapStream
     * @returns Object containing the transaction signature if successful
     * @throws Error if transaction processing fails
     */
    submitSignedTransaction: t.procedure
      .input(
        z.object({
          signature: z.string(),
          base64Transaction: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        await ctx.tubService.signAndSendTransaction(ctx.jwtToken, input.signature, input.base64Transaction);
      }),

    fetchSwap: t.procedure
      .input(
        z.object({
          buyTokenId: z.string(),
          sellTokenId: z.string(),
          sellQuantity: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.fetchSwap(ctx.jwtToken, input);
      }),

    fetchPresignedSwap: t.procedure
      .input(
        z.object({
          buyTokenId: z.string(),
          sellTokenId: z.string(),
          sellQuantity: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.fetchPresignedSwap(ctx.jwtToken, input);
      }),

    get1USDCToSOLTransaction: t.procedure.mutation(async ({ ctx }) => {
      return await ctx.tubService.get1USDCToSOLTransaction(ctx.jwtToken);
    }),

    stopSwapStream: t.procedure.mutation(async ({ ctx }) => {
      await ctx.tubService.stopSwapStream(ctx.jwtToken);
    }),

    getSignedTransfer: t.procedure
      .input(z.object({ fromAddress: z.string(), toAddress: z.string(), amount: z.string(), tokenId: z.string() }))
      .mutation(async ({ ctx, input }) => {
        const amountBigInt = BigInt(input.amount);
        return await ctx.tubService.getSignedTransfer(ctx.jwtToken, { ...input, amount: amountBigInt });
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
