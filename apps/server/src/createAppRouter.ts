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
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
