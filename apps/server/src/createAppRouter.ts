import { initTRPC } from "@trpc/server";
import { observable } from "@trpc/server/observable";
import { z } from "zod";
import { TubService } from "./TubService";
import { PrebuildSwapResponse } from "../types/PrebuildSwapRequest";

export type AppContext = {
  tubService: TubService;
  jwtToken: string;
};

// eslint-disable-next-line @typescript-eslint/explicit-function-return-type
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

    /**
     * Purchases a specified amount of tokens
     * @param tokenId - The unique identifier of the token to buy
     * @param amount - The amount of tokens to purchase as a string (will be converted to BigInt)
     * @param overridePrice - Optional override price for the token purchase
     * @returns Result of the token purchase operation
     */
    buyToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
          tokenPrice: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.buyToken(
          ctx.jwtToken,
          input.tokenId,
          BigInt(input.amount),
          Number(input.tokenPrice),
        );
      }),

    /**
     * Sells a specified amount of tokens
     * @param tokenId - The unique identifier of the token to sell
     * @param amount - The amount of tokens to sell as a string (will be converted to BigInt)
     * @param overridePrice - Optional override price for the token sale
     * @returns Result of the token sale operation
     */
    sellToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
          tokenPrice: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.sellToken(
          ctx.jwtToken,
          input.tokenId,
          BigInt(input.amount),
          Number(input.tokenPrice),
        );
      }),

    airdropNativeToUser: t.procedure
      .input(
        z.object({
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.airdropNativeToUser(ctx.jwtToken, BigInt(input.amount));
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
              subject = s;
              subject.subscribe({
                next: (response: PrebuildSwapResponse) => {
                  emit.next(response);
                },
                error: (error: Error) => {
                  console.error("Swap stream error:", error);
                  emit.error(error);
                },
              });
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
          buyTokenId: z.string().optional(),
          sellTokenId: z.string().optional(),
          sellQuantity: z.number().optional(),
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
