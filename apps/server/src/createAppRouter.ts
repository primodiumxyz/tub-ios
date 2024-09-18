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
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
