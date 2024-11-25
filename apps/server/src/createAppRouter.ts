import { initTRPC } from "@trpc/server";
import { z } from "zod";
import { TubService } from "./TubService";

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

    getSolUsdPrice: t.procedure.query(async ({ ctx }) => {
      return await ctx.tubService.getSolUsdPrice();
    }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
