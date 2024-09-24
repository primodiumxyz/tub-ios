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
    getAllTokens: t.procedure.query(async ({ ctx }) => {
      return ctx.tubService.getAllTokens();
    }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
