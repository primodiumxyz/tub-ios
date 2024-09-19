import { initTRPC, TRPCError } from "@trpc/server";
import { isAddress } from "viem";
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
    incrementCall: t.procedure.mutation(({ ctx }) => {
      ctx.tubService.incrementCall();
    }),
    createTokenCall: t.procedure.mutation(({ ctx }) => {
      ctx.tubService.createTokenCall();
    }),
    mintCall: t.procedure.mutation(({ ctx }) => {
      ctx.tubService.mintCall();
    }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
