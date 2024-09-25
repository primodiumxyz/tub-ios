import { initTRPC } from "@trpc/server";
import { observable } from "@trpc/server/observable";
import { z } from "zod";
import { TubService } from "./TubService";

export type AppContext = {
  tubService: TubService;
};

// eslint-disable-next-line @typescript-eslint/explicit-function-return-type
export function createAppRouter() {
  const t = initTRPC.context<AppContext>().create();
  return t.router({
    getStatus: t.procedure.query(({ ctx }) => {
      return ctx.tubService.getStatus();
    }),
    incrementCall: t.procedure.mutation(async ({ ctx }) => {
      await ctx.tubService.incrementCall();
    }),
    onCounterUpdate: t.procedure.subscription(({ ctx }) => {
      return observable<number>((emit) => {
        const onUpdate = (value: number) => {
          emit.next(value);
        };
        ctx.tubService.subscribeToCounter(onUpdate);
        return () => {
          ctx.tubService.unsubscribeFromCounter(onUpdate);
        };
      });
    }),
    registerNewUser: t.procedure
      .input(
        z.object({
          username: z.string(),
          airdropAmount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.registerNewUser(input.username, BigInt("100"));
      }), 
    buyToken: t.procedure
      .input(
        z.object({
          accountId: z.string(),
          tokenId: z.string(),
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.buyToken(input.accountId, input.tokenId, BigInt(input.amount));
      }),
    sellToken: t.procedure
      .input(
        z.object({
          accountId: z.string(),
          tokenId: z.string(),
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.sellToken(input.accountId, input.tokenId, BigInt(input.amount));
      }),
    registerNewToken: t.procedure
      .input(
        z.object({
          name: z.string(),
          symbol: z.string(),
          supply: z.string().optional(),
          uri: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.registerNewToken(input.name, input.symbol, input.supply ? BigInt(input.supply) : undefined, input.uri);
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
