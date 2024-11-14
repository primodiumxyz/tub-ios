import { initTRPC } from "@trpc/server";
import { z } from "zod";
import { TubService } from "./TubService";
import { observable } from '@trpc/server/observable';
import { PublicKey, Transaction } from "@solana/web3.js";

export type AppContext = {
  tubService: TubService;
  jwtToken: string;
};

// eslint-disable-next-line @typescript-eslint/explicit-function-return-type
export function createAppRouter() {
  const t = initTRPC.context<AppContext>().create();
  return t.router({
    getStatus: t.procedure.query(({ ctx }) => {
      return ctx.tubService.getStatus();
    }),
    buyToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
          overridePrice: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.buyToken(
          ctx.jwtToken,
          input.tokenId,
          BigInt(input.amount),
          input.overridePrice ? BigInt(input.overridePrice) : undefined,
        );
      }),
    sellToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
          overridePrice: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.sellToken(
          ctx.jwtToken,
          input.tokenId,
          BigInt(input.amount),
          input.overridePrice ? BigInt(input.overridePrice) : undefined,
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
    swapStream: t.procedure
      .input(z.object({
        buyTokenId: z.string().optional(),
        sellTokenId: z.string().optional(),
        sellQuantity: z.number().optional(),
        userPublicKey: z.string()
      }))
      .subscription(({ ctx, input }) => {
        // Validate the public key before proceeding
        try {
          new PublicKey(input.userPublicKey);
        } catch (e) {
          throw new Error('Invalid user public key');
        }

        // Validate that we have both buy and sell token
        if (!input.buyTokenId || !input.sellTokenId) {
          throw new Error('Must provide both buyTokenId and sellTokenId');
        }

        return observable((emit) => {
          let subscription: any;
          
          ctx.tubService.startSwapStream(ctx.jwtToken, {
            ...input,
            userId: ctx.jwtToken,
            userPublicKey: new PublicKey(input.userPublicKey)
          }).then(subject => {
            subscription = subject.subscribe({
              next: (transaction: Transaction) => {
                emit.next(transaction);
              },
              error: (error: Error) => {
                console.error('Swap stream error:', error);
                emit.error(error);
              }
            });
          }).catch(error => {
            console.error('Failed to start swap stream:', error);
            emit.error(error);
          });

          return () => {
            if (subscription) subscription.unsubscribe();
            ctx.tubService.stopSwapStream(ctx.jwtToken);
          };
        });
      }),
    updateSwapRequest: t.procedure
      .input(z.object({
        buyTokenId: z.string().optional(),
        sellTokenId: z.string().optional(),
        sellQuantity: z.number().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        await ctx.tubService.updateSwapRequest(ctx.jwtToken, input);
      }),
    submitSignedTransaction: t.procedure
      .input(z.object({
        signature: z.string(),
        base64Transaction: z.string(),
      }))
      .mutation(async ({ ctx, input }) => {
        await ctx.tubService.signAndSendTransaction(
          ctx.jwtToken,
          input.signature,
          input.base64Transaction
        );
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
