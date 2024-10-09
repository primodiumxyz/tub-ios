import { z, ZodError, ZodIntersection, ZodTypeAny } from "zod";

const commonSchema = z.object({
  NODE_ENV: z.enum(["local", "dev", "test", "prod"]).default("local"),
  SERVER_HOST: z.string().default("0.0.0.0"),
  SERVER_PORT: z.coerce.number().positive().default(8888),
  HASURA_ADMIN_SECRET: z.string(),
  GRAPHQL_URL: z.string().default("https://tub-graphql.primodium.ai/v1/graphql"),
  ALCHEMY_RPC_URL: z.string().default("https://solana-mainnet.g.alchemy.com/v2/"),
  HELIUS_WS_URL: z.string().default("wss://mainnet.helius-rpc.com/?api-key=)"),
});

export function parseEnv<TSchema extends ZodTypeAny | undefined = undefined>(
  schema?: TSchema,
): z.infer<TSchema extends ZodTypeAny ? ZodIntersection<typeof commonSchema, TSchema> : typeof commonSchema> {
  const envSchema = schema !== undefined ? z.intersection(commonSchema, schema) : commonSchema;
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof ZodError) {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { _errors, ...invalidEnvVars } = error.format();
      console.error(`\nMissing or invalid environment variables:\n\n  ${Object.keys(invalidEnvVars).join("\n  ")}\n`);
      process.exit(1);
    }
    throw error;
  }
}
