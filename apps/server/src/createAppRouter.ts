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
          userId: z.string(),
          tokenId: z.string(),
          amount: z.string(),
          overridePrice: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.buyToken(
          input.userId,
          input.tokenId,
          BigInt(input.amount),
          input.overridePrice ? BigInt(input.overridePrice) : undefined,
        );
      }),
    sellToken: t.procedure
      .input(
        z.object({
          userId: z.string(),
          tokenId: z.string(),
          amount: z.string(),
          overridePrice: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.sellToken(
          input.userId,
          input.tokenId,
          BigInt(input.amount),
          input.overridePrice ? BigInt(input.overridePrice) : undefined,
        );
      }),
   
    airdropNativeToUser: t.procedure
      .input(
        z.object({
          userId: z.string(),
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.airdropNativeToUser(input.userId, BigInt(input.amount));
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
