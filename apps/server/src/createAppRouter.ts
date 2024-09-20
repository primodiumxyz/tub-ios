import { initTRPC, TRPCError } from "@trpc/server";
import { isAddress } from "viem";
import { z } from "zod";
import { observable } from '@trpc/server/observable';
import { WebSocket } from 'ws';

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
    incrementCall: t.procedure.mutation(({ ctx }) => {
      ctx.tubService.incrementCall();
    }),
    onCounterUpdate: t.procedure.subscription(({ctx}) => {
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
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
