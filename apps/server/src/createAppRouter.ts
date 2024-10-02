import { initTRPC } from "@trpc/server";
import { observable } from "@trpc/server/observable";
import { z } from "zod";
import { TubService } from "./TubService";
import jwt from "jsonwebtoken";
import { parseEnv } from "@bin/parseEnv";
import { config } from "dotenv";
config({ path: "../../.env" });

const env = parseEnv();

export type AppContext = {
  tubService: TubService;
  jwtToken: string;
};

const verifyJWT = (token: string) => {
  try {
    const payload = jwt.verify(token, env.PRIVATE_KEY) as jwt.JwtPayload;
    return payload.uuid;
  } catch (e: any) {
    throw new Error(`Invalid JWT: ${e.message}`);
  }
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
          airdropAmount: z.string().optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        return await ctx.tubService.registerNewUser(input.username, input.airdropAmount ? BigInt(input.airdropAmount) : BigInt("100"));
      }), 
    buyToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const uuid = verifyJWT(ctx.jwtToken);
        return await ctx.tubService.buyToken(uuid, input.tokenId, BigInt(input.amount));
      }),
    sellToken: t.procedure
      .input(
        z.object({
          tokenId: z.string(),
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const uuid = verifyJWT(ctx.jwtToken);
        return await ctx.tubService.sellToken(uuid, input.tokenId, BigInt(input.amount));
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
    airdropNativeToUser: t.procedure
      .input(
        z.object({
          amount: z.string(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const uuid = verifyJWT(ctx.jwtToken);
        return await ctx.tubService.airdropNativeToUser(uuid, BigInt(input.amount));
      }),
  });
}

export type AppRouter = ReturnType<typeof createAppRouter>;
