import { initTRPC } from "@trpc/server";
import { observable } from "@trpc/server/observable";
import { z } from "zod";
import { TubService } from "./services/TubService";
import { ClientEvent, PrebuildSwapResponse, UserPrebuildSwapRequest } from "./types";
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

const clientEventSchema = z.object({
  userWallet: z.string(),
  userAgent: z.string(),
  source: z.string().optional(),
  errorDetails: z.string().optional(),
  buildVersion: z.string().optional(),
}) satisfies z.ZodType<ClientEvent>;

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

    getSolUsdPrice: t.procedure.query(async ({ ctx }) => {
      return await ctx.tubService.getSolUsdPrice();
    }),

    subscribeSolPrice: t.procedure.subscription(({ ctx }) => {
      return observable<number>((emit) => {
        const onPrice = (price: number) => {
          emit.next(price);
        };

        const cleanup = ctx.tubService.subscribeSolPrice(onPrice);
        return () => {
          cleanup();
        };
      });
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
        return await ctx.tubService.signAndSendTransaction(ctx.jwtToken, input.signature, input.base64Transaction);
      }),

    fetchSwap: t.procedure
      .input(
        z.object({
          buyTokenId: z.string(),
          sellTokenId: z.string(),
          sellQuantity: z.number(),
          slippageBps: z.number().optional(),
        }),
      )
      .query(async ({ ctx, input }) => {
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
      .query(async ({ ctx, input }) => {
        return await ctx.tubService.fetchPresignedSwap(ctx.jwtToken, input);
      }),

    stopSwapStream: t.procedure.mutation(async ({ ctx }) => {
      await ctx.tubService.stopSwapStream(ctx.jwtToken);
    }),

    recordTokenPurchase: t.procedure
      .input(
        z.object({
          ...clientEventSchema.shape,
          tokenMint: z.string(),
          tokenAmount: z.string(),
          tokenPriceUsd: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordTokenPurchase(input, ctx.jwtToken);
      }),

    recordTokenSale: t.procedure
      .input(
        z.object({
          ...clientEventSchema.shape,
          tokenMint: z.string(),
          tokenAmount: z.string(),
          tokenPriceUsd: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordTokenSale(input, ctx.jwtToken);
      }),

    recordLoadingTime: t.procedure
      .input(
        z.object({
          ...clientEventSchema.shape,
          identifier: z.string(),
          timeElapsedMs: z.number(),
          attemptNumber: z.number(),
          totalTimeMs: z.number(),
          averageTimeMs: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordLoadingTime(input, ctx.jwtToken);
      }),

    recordAppDwellTime: t.procedure
      .input(
        z.object({
          ...clientEventSchema.shape,
          dwellTimeMs: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordAppDwellTime(input, ctx.jwtToken);
      }),

    recordTokenDwellTime: t.procedure
      .input(
        z.object({
          ...clientEventSchema.shape,
          tokenMint: z.string(),
          dwellTimeMs: z.number(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.recordTokenDwellTime(input, ctx.jwtToken);
      }),

    getBalance: t.procedure.query(async ({ ctx }) => {
      return await ctx.tubService.getBalance(ctx.jwtToken);
    }),

    getAllTokenBalances: t.procedure.query(async ({ ctx }) => {
      return await ctx.tubService.getAllTokenBalances(ctx.jwtToken);
    }),

    getTokenBalance: t.procedure
      .input(
        z.object({
          tokenMint: z.string(),
        }),
      )
      .query(async ({ ctx, input }) => {
        return await ctx.tubService.getTokenBalance(ctx.jwtToken, input.tokenMint);
      }),

    fetchTransferTx: t.procedure
      .input(
        z.object({
          toAddress: z.string(),
          amount: z.string(),
          tokenId: z.string(),
        }),
      )
      .query(async ({ ctx, input }) => {
        return await ctx.tubService.fetchTransferTx(ctx.jwtToken, input);
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
